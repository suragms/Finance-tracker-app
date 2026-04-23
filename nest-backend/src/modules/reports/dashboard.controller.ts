import { Controller, Get, Req, UseGuards } from "@nestjs/common";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { WorkspaceContextGuard } from "../workspaces/workspace-context.guard";
import { RequestWithWorkspace } from "../workspaces/workspace.types";
import { ReportsService } from "./reports.service";

@Controller("dashboard")
@UseGuards(JwtAuthGuard, WorkspaceContextGuard)
export class DashboardController {
  constructor(private readonly reports: ReportsService) {}

  @Get("overview")
  overview(@Req() req: RequestWithWorkspace) {
    return this.reports.dashboardOverview(req.workspaceContext);
  }
}

