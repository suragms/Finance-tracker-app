import { Module } from '@nestjs/common';
import { AiModule } from '../ai/ai.module';
import { WorkspacesModule } from '../workspaces/workspaces.module';
import { DashboardController } from './dashboard.controller';
import { ReportsController } from './reports.controller';
import { ReportsService } from './reports.service';
import { InsightsController } from './insights.controller';

@Module({
  imports: [AiModule, WorkspacesModule],
  controllers: [ReportsController, InsightsController, DashboardController],
  providers: [ReportsService],
  exports: [ReportsService],
})
export class ReportsModule {}
