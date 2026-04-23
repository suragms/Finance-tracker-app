import { Injectable, Logger, NotFoundException, OnModuleInit } from '@nestjs/common';
import {
  ExpenseSource,
  Frequency,
  IncomeSource,
  NotificationChannel,
  NotificationCategory,
  RecurringMode,
  RecurringStatus,
} from '@prisma/client';
import { Cron, CronExpression } from '@nestjs/schedule';
import { addDays, addMonths, addWeeks, addYears } from 'date-fns';
import { PrismaService } from '../../prisma/prisma.service';
import { QueueService } from '../../queue/queue.service';
import { AccountsService } from '../accounts/accounts.service';
import { NotificationsService } from '../notifications/notifications.service';
import { CreateRecurringDto } from './dto/create-recurring.dto';

@Injectable()
export class RecurringService implements OnModuleInit {
  private readonly logger = new Logger(RecurringService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly queue: QueueService,
    private readonly accounts: AccountsService,
    private readonly notifications: NotificationsService,
  ) {}

  onModuleInit() {
    this.queue.createRecurringWorker(async (job) => {
      await this.processRecurring(job.data.recurringId);
    });
    if (!this.queue.redisAvailable) {
      this.logger.warn('Recurring worker not started (no Redis); due items are processed inline from the cron job');
    }
  }

  list(userId: string) {
    return this.prisma.recurringExpense.findMany({
      where: { userId },
      include: { category: true, account: true },
      orderBy: { nextDate: 'asc' },
    });
  }

  create(userId: string, dto: CreateRecurringDto) {
    return this.prisma.recurringExpense.create({
      data: {
        userId,
        amount: dto.amount,
        frequency: dto.frequency,
        mode: dto.mode ?? RecurringMode.auto_create,
        nextDate: new Date(dto.nextDate),
        categoryId: dto.categoryId,
        accountId: dto.accountId,
        title: dto.title,
        note: dto.note,
      },
      include: { category: true, account: true },
    });
  }

  async setActive(userId: string, id: string, active: boolean) {
    const row = await this.prisma.recurringExpense.findFirst({
      where: { id, userId },
    });
    if (!row) throw new NotFoundException('Recurring expense not found');
    return this.prisma.recurringExpense.update({
      where: { id },
      data: { active },
      include: { category: true, account: true },
    });
  }

  @Cron(CronExpression.EVERY_DAY_AT_8AM)
  async scheduleDueRecurring() {
    await this.checkAndProcessDueRecurring();
  }

  async checkAndProcessDueRecurring() {
    if (this.prisma.databaseDisabled) return;
    const due = await this.prisma.recurringExpense.findMany({
      where: {
        active: true,
        status: RecurringStatus.pending,
        nextDate: { lte: new Date() },
      },
    });
    for (const item of due) {
      if (!this.queue.recurringQueue) {
        await this.processRecurring(item.id);
        continue;
      }
      await this.queue.recurringQueue.add(
        'apply-recurring',
        { recurringId: item.id },
        { jobId: `recurring-${item.id}-${item.nextDate.toISOString().slice(0, 10)}` },
      );
    }
  }

  async processRecurring(recurringId: string) {
    const item = await this.prisma.recurringExpense.findUnique({ where: { id: recurringId } });
    if (!item || !item.active || item.status !== RecurringStatus.pending) return;

    if (item.mode === RecurringMode.reminder_only) {
      const dueDay = item.nextDate.toISOString().slice(0, 10);
      const dedupeKey = `recurring-reminder-${item.id}-${dueDay}`;
      await this.prisma.$transaction(async (tx) => {
        await tx.notification.create({
          data: {
            userId: item.userId,
            title: `${item.title} due today`,
            body: `₹${item.amount.toFixed(2)} payment is due`,
            category: NotificationCategory.recurring,
            channel: NotificationChannel.in_app,
            dedupeKey,
            date: new Date(),
          },
        });
        await tx.recurringExpense.update({
          where: { id: recurringId },
          data: { status: RecurringStatus.pending },
        });
      });
      return;
    }

    const occurrenceDate = new Date();
    await this.prisma.$transaction(async (tx) => {
      const recurringType = (item as unknown as { type?: string }).type;
      if (recurringType === 'income' && item.accountId) {
        await tx.income.create({
          data: {
            userId: item.userId,
            accountId: item.accountId,
            amount: item.amount,
            date: occurrenceDate,
            note: `Auto: ${item.title}`,
            source: IncomeSource.other,
          },
        });
      } else {
        const expense = await tx.expense.create({
          data: {
            userId: item.userId,
            categoryId: item.categoryId,
            amount: item.amount,
            date: occurrenceDate,
            note: `Auto: ${item.title}`,
            currency: item.currency,
            source: ExpenseSource.recurring_generated,
            recurringExpenseId: item.id,
            accountId: item.accountId ?? undefined,
          },
          include: { category: true },
        });
        if (item.accountId) {
          await this.accounts.applyExpenseCreatedTx(tx, item.userId, {
            accountId: expense.accountId,
            amount: expense.amount,
            category: expense.category,
          });
        }
      }
      await tx.recurringExpense.update({
        where: { id: recurringId },
        data: {
          status: RecurringStatus.paid,
          nextDate: this.nextDate(item.nextDate, item.frequency),
        },
      });
    });

    const postedDedupe = `recurring-posted-${item.id}-${occurrenceDate.toISOString().slice(0, 10)}`;
    void this.notifications
      .create(item.userId, `Expense logged: ${item.title}`, NotificationCategory.recurring, {
        body: `${item.amount.toFixed(2)} ${item.currency}`,
        dedupeKey: postedDedupe,
      })
      .catch((e) => this.logger.warn(`recurring push notify: ${(e as Error).message}`));
  }

  async markPaid(userId: string, id: string) {
    const row = await this.prisma.recurringExpense.findFirst({ where: { id, userId } });
    if (!row) throw new NotFoundException('Recurring expense not found');
    return this.prisma.recurringExpense.update({
      where: { id },
      data: {
        status: RecurringStatus.paid,
        nextDate: this.nextDate(row.nextDate, row.frequency),
      },
      include: { category: true, account: true },
    });
  }

  private nextDate(date: Date, frequency: Frequency) {
    switch (frequency) {
      case Frequency.daily:
        return addDays(date, 1);
      case Frequency.weekly:
        return addWeeks(date, 1);
      case Frequency.monthly:
        return addMonths(date, 1);
      case Frequency.quarterly:
        return addMonths(date, 3);
      case Frequency.yearly:
        return addYears(date, 1);
      default:
        return addMonths(date, 1);
    }
  }
}
