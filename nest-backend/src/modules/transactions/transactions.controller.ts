import { Controller, Post, Body, Req, UseGuards, BadRequestException } from '@nestjs/common';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { WorkspaceContextGuard } from '../workspaces/workspace-context.guard';
import { RequestWithWorkspace } from '../workspaces/workspace.types';
import { ExpensesService } from '../expenses/expenses.service';
import { IncomesService } from '../incomes/incomes.service';
import { AccountsService } from '../accounts/accounts.service';
import { NotificationsService } from '../notifications/notifications.service';
import { IncomeSource, NotificationCategory } from '@prisma/client';

import { CreateTransactionDto } from './dto/create-transaction.dto';

@Controller('transactions')
@UseGuards(JwtAuthGuard, WorkspaceContextGuard)
export class TransactionsController {
  constructor(
    private readonly expensesService: ExpensesService,
    private readonly incomesService: IncomesService,
    private readonly accountsService: AccountsService,
    private readonly notificationsService: NotificationsService,
  ) {}

  @Post()
  async createTransaction(@Req() req: RequestWithWorkspace, @Body() dto: CreateTransactionDto) {
    const { workspaceContext } = req;
    
    if (dto.amount <= 0) {
      throw new BadRequestException('Amount must be greater than zero');
    }

    if (dto.type === 'expense') {
      if (!dto.category_id) throw new BadRequestException('Category is required for expenses');
      const row = await this.expensesService.create(workspaceContext, {
        amount: dto.amount,
        categoryId: dto.category_id,
        accountId: dto.account_id,
        date: dto.date,
        note: dto.note,
      });
      await this.notificationsService.create(workspaceContext.ownerUserId, `₹${dto.amount} expense added`, NotificationCategory.system, { body: `You added an expense of ₹${dto.amount}.` });
      return row;
    }

    if (dto.type === 'income') {
      const row = await this.incomesService.create(workspaceContext, {
        amount: dto.amount,
        source: dto.category_id as IncomeSource || 'other',
        accountId: dto.account_id,
        date: dto.date,
        note: dto.note,
      });
      await this.notificationsService.create(workspaceContext.ownerUserId, `₹${dto.amount} income added`, NotificationCategory.system, { body: `You added an income of ₹${dto.amount}.` });
      return row;
    }

    if (dto.type === 'transfer') {
      if (!dto.to_account_id) throw new BadRequestException('Destination account is required for transfers');
      return this.accountsService.transferForWorkspace(workspaceContext, {
        fromAccountId: dto.account_id,
        toAccountId: dto.to_account_id,
        amount: dto.amount,
        note: dto.note,
      });
    }

    throw new BadRequestException('Invalid transaction type');
  }
}
