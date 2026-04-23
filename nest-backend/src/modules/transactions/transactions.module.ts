import { Module } from '@nestjs/common';
import { TransactionsController } from './transactions.controller';
import { ExpensesModule } from '../expenses/expenses.module';
import { IncomesModule } from '../incomes/incomes.module';
import { AccountsModule } from '../accounts/accounts.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { WorkspacesModule } from '../workspaces/workspaces.module';

@Module({
  imports: [ExpensesModule, IncomesModule, AccountsModule, NotificationsModule, WorkspacesModule],
  controllers: [TransactionsController],
})
export class TransactionsModule {}
