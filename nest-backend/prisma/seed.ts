import * as bcrypt from 'bcrypt';
import {
  AccountType,
  CategorySystemKey,
  CategoryType,
  Frequency,
  IncomeSource,
  Prisma,
  PrismaClient,
  RecurringMode,
  UserRole,
  WorkspaceRole,
} from '@prisma/client';

const prisma = new PrismaClient();

const DEMO_EMAIL = 'demo@moneyflow.app';
const DEMO_PASSWORD = 'Demo@1234';
const DEMO_NAME = 'Surag';
const DEMO_PHONE = '+919876543210';

const ADMIN_EMAIL = 'admin@moneyflow.app';
const ADMIN_PASSWORD = 'Admin@1234';

function nk(name: string): string {
  return name.trim().replace(/\s+/g, ' ').toLowerCase();
}

function randInt(min: number, max: number): number {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

function dayAtNoon(year: number, monthIndex: number, day: number): Date {
  return new Date(year, monthIndex, day, 12, 0, 0, 0);
}

function randomDateInMonth(year: number, monthIndex: number, fromDay = 1, toDay?: number): Date {
  const monthEnd = new Date(year, monthIndex + 1, 0).getDate();
  const end = toDay == null ? monthEnd : Math.min(toDay, monthEnd);
  const start = Math.min(Math.max(fromDay, 1), end);
  return dayAtNoon(year, monthIndex, randInt(start, end));
}

type CuratedCategory = {
  name: string;
  key: CategorySystemKey;
  sort: number;
  subs: string[];
};

const CURATED_CATEGORIES: CuratedCategory[] = [
  {
    name: 'Daily Expenses',
    key: CategorySystemKey.daily_expenses,
    sort: 0,
    subs: ['Food', 'Transport', 'Shopping', 'Entertainment', 'Health'],
  },
  {
    name: 'Household',
    key: CategorySystemKey.household,
    sort: 1,
    subs: ['Rent', 'Electricity', 'Water', 'Internet', 'Maintenance'],
  },
  {
    name: 'Vehicle',
    key: CategorySystemKey.vehicle,
    sort: 2,
    subs: ['Fuel', 'Insurance', 'Service', 'EMI', 'Parking'],
  },
  {
    name: 'Insurance',
    key: CategorySystemKey.insurance,
    sort: 3,
    subs: ['Life', 'Health', 'Vehicle', 'Property'],
  },
  {
    name: 'Financial',
    key: CategorySystemKey.financial,
    sort: 4,
    subs: ['EMI', 'Investment', 'Savings', 'Tax'],
  },
  {
    name: 'Donations',
    key: CategorySystemKey.donations,
    sort: 5,
    subs: ['Charity', 'Religious', 'Other'],
  },
  {
    name: 'Business',
    key: CategorySystemKey.business,
    sort: 6,
    subs: ['Salary', 'Office', 'Marketing', 'Travel', 'Utilities'],
  },
  {
    name: 'Custom',
    key: CategorySystemKey.custom,
    sort: 7,
    subs: [],
  },
];

async function ensureWorkspace(userId: string, name: string) {
  let ws = await prisma.workspace.findFirst({ where: { ownerUserId: userId } });
  if (!ws) {
    ws = await prisma.workspace.create({
      data: { name: `${name}'s workspace`, ownerUserId: userId },
    });
  }

  await prisma.workspaceMember.upsert({
    where: { workspaceId_userId: { workspaceId: ws.id, userId } },
    update: { role: WorkspaceRole.owner },
    create: { workspaceId: ws.id, userId, role: WorkspaceRole.owner },
  });

  return ws;
}

async function ensureUsers() {
  const demoHash = await bcrypt.hash(DEMO_PASSWORD, 12);
  const adminHash = await bcrypt.hash(ADMIN_PASSWORD, 12);

  const demoUser = await prisma.user.upsert({
    where: { email: DEMO_EMAIL },
    update: {
      name: DEMO_NAME,
      phone: DEMO_PHONE,
      passwordHash: demoHash,
      role: UserRole.owner,
      deletedAt: null,
      currency: 'INR',
    },
    create: {
      name: DEMO_NAME,
      email: DEMO_EMAIL,
      phone: DEMO_PHONE,
      passwordHash: demoHash,
      role: UserRole.owner,
      currency: 'INR',
    },
  });

  const adminUser = await prisma.user.upsert({
    where: { email: ADMIN_EMAIL },
    update: {
      name: 'MoneyFlow Admin',
      passwordHash: adminHash,
      role: UserRole.owner,
      deletedAt: null,
      currency: 'INR',
    },
    create: {
      name: 'MoneyFlow Admin',
      email: ADMIN_EMAIL,
      passwordHash: adminHash,
      role: UserRole.owner,
      currency: 'INR',
    },
  });

  await prisma.admin.upsert({
    where: { email: ADMIN_EMAIL },
    update: {
      name: 'MoneyFlow Admin',
      passwordHash: adminHash,
      role: 'admin',
    },
    create: {
      email: ADMIN_EMAIL,
      name: 'MoneyFlow Admin',
      passwordHash: adminHash,
      role: 'admin',
    },
  });

  return { demoUser, adminUser };
}

async function clearDemoData(userId: string) {
  await prisma.$transaction([
    prisma.budget.deleteMany({ where: { userId } }),
    prisma.recurringExpense.deleteMany({ where: { userId } }),
    prisma.income.deleteMany({ where: { userId } }),
    prisma.expense.deleteMany({ where: { userId } }),
    prisma.subCategory.deleteMany({ where: { category: { userId } } }),
    prisma.category.deleteMany({ where: { userId } }),
    prisma.account.deleteMany({ where: { userId } }),
  ]);
}

async function seedDemoData(userId: string) {
  const ws = await ensureWorkspace(userId, DEMO_NAME);
  await clearDemoData(userId);

  const account = await prisma.account.create({
    data: {
      userId,
      workspaceId: ws.id,
      name: 'Demo Salary Account',
      type: AccountType.bank,
      balance: new Prisma.Decimal('0'),
    },
  });

  const categoryByKey = new Map<CategorySystemKey, { id: string; name: string }>();
  const subByPath = new Map<string, string>();

  for (const c of CURATED_CATEGORIES) {
    const cat = await prisma.category.create({
      data: {
        userId,
        name: c.name,
        nameKey: nk(c.name),
        systemKey: c.key,
        sortOrder: c.sort,
        type: CategoryType.expense,
      },
    });
    categoryByKey.set(c.key, cat);
    for (let i = 0; i < c.subs.length; i++) {
      const subName = c.subs[i];
      const sub = await prisma.subCategory.create({
        data: {
          categoryId: cat.id,
          name: subName,
          nameKey: nk(subName),
          sortOrder: i,
        },
      });
      subByPath.set(`${c.key}:${nk(subName)}`, sub.id);
    }
  }

  const dailyCat = categoryByKey.get(CategorySystemKey.daily_expenses)!;
  const householdCat = categoryByKey.get(CategorySystemKey.household)!;
  const vehicleCat = categoryByKey.get(CategorySystemKey.vehicle)!;
  const insuranceCat = categoryByKey.get(CategorySystemKey.insurance)!;
  const financialCat = categoryByKey.get(CategorySystemKey.financial)!;

  const foodSubId = subByPath.get(`${CategorySystemKey.daily_expenses}:${nk('Food')}`)!;
  const transportSubId = subByPath.get(`${CategorySystemKey.daily_expenses}:${nk('Transport')}`)!;
  const rentSubId = subByPath.get(`${CategorySystemKey.household}:${nk('Rent')}`)!;
  const fuelSubId = subByPath.get(`${CategorySystemKey.vehicle}:${nk('Fuel')}`)!;

  const now = new Date();
  const months = [2, 1, 0].map((mBack) => new Date(now.getFullYear(), now.getMonth() - mBack, 1));

  let totalIncome = new Prisma.Decimal('0');
  let totalExpense = new Prisma.Decimal('0');

  for (const monthStart of months) {
    const y = monthStart.getFullYear();
    const m = monthStart.getMonth();
    const monthEndDay = new Date(y, m + 1, 0).getDate();

    // Demo income: salary on 1st of each month.
    const salary = new Prisma.Decimal('50000');
    totalIncome = totalIncome.plus(salary);
    await prisma.income.create({
      data: {
        userId,
        accountId: account.id,
        amount: salary,
        source: IncomeSource.salary,
        date: dayAtNoon(y, m, 1),
        note: 'Monthly salary',
      },
    });

    // Demo income: freelance in random months.
    if (Math.random() < 0.7) {
      const freelance = new Prisma.Decimal(randInt(5000, 15000));
      totalIncome = totalIncome.plus(freelance);
      await prisma.income.create({
        data: {
          userId,
          accountId: account.id,
          amount: freelance,
          source: IncomeSource.business,
          date: randomDateInMonth(y, m, 5, 28),
          note: 'Freelance project payout',
        },
      });
    }

    // Food: 3-5 entries per week, ₹200-₹800.
    let weekStart = 1;
    while (weekStart <= monthEndDay) {
      const weekEnd = Math.min(weekStart + 6, monthEndDay);
      const count = randInt(3, 5);
      for (let i = 0; i < count; i++) {
        const amt = new Prisma.Decimal(randInt(200, 800));
        totalExpense = totalExpense.plus(amt);
        await prisma.expense.create({
          data: {
            userId,
            workspaceId: ws.id,
            accountId: account.id,
            categoryId: dailyCat.id,
            subCategoryId: foodSubId,
            amount: amt,
            date: randomDateInMonth(y, m, weekStart, weekEnd),
            note: 'Food & groceries',
            currency: 'INR',
          },
        });
      }
      weekStart += 7;
    }

    // Transport: randomized monthly spread, ₹50-₹500.
    const transportEntries = randInt(12, 18);
    for (let i = 0; i < transportEntries; i++) {
      const amt = new Prisma.Decimal(randInt(50, 500));
      totalExpense = totalExpense.plus(amt);
      await prisma.expense.create({
        data: {
          userId,
          workspaceId: ws.id,
          accountId: account.id,
          categoryId: dailyCat.id,
          subCategoryId: transportSubId,
          amount: amt,
          date: randomDateInMonth(y, m),
          note: 'Auto/metro/cab',
          currency: 'INR',
        },
      });
    }

    // Household/Rent: once per month, ₹8,000-₹15,000.
    const rentAmt = new Prisma.Decimal(randInt(8000, 15000));
    totalExpense = totalExpense.plus(rentAmt);
    await prisma.expense.create({
      data: {
        userId,
        workspaceId: ws.id,
        accountId: account.id,
        categoryId: householdCat.id,
        subCategoryId: rentSubId,
        amount: rentAmt,
        date: randomDateInMonth(y, m, 2, 7),
        note: 'Monthly house rent',
        currency: 'INR',
      },
    });

    // Vehicle/Fuel: monthly total expense, ₹2,000-₹4,000.
    const fuelAmt = new Prisma.Decimal(randInt(2000, 4000));
    totalExpense = totalExpense.plus(fuelAmt);
    await prisma.expense.create({
      data: {
        userId,
        workspaceId: ws.id,
        accountId: account.id,
        categoryId: vehicleCat.id,
        subCategoryId: fuelSubId,
        amount: fuelAmt,
        date: randomDateInMonth(y, m, 8, 26),
        note: 'Vehicle fuel refill',
        currency: 'INR',
      },
    });
  }

  // Recurring rules.
  const nextMonth = new Date(now.getFullYear(), now.getMonth() + 1, 5, 12, 0, 0, 0);
  const nextYear = new Date(now.getFullYear() + 1, now.getMonth(), 10, 12, 0, 0, 0);

  await prisma.recurringExpense.createMany({
    data: [
      {
        userId,
        accountId: account.id,
        categoryId: householdCat.id,
        amount: new Prisma.Decimal('12000'),
        frequency: Frequency.monthly,
        mode: RecurringMode.reminder_only,
        title: 'Rent',
        note: 'Monthly house rent',
        nextDate: nextMonth,
        active: true,
      },
      {
        userId,
        accountId: account.id,
        categoryId: financialCat.id,
        amount: new Prisma.Decimal('8500'),
        frequency: Frequency.monthly,
        mode: RecurringMode.reminder_only,
        title: 'EMI',
        note: 'Monthly loan EMI',
        nextDate: nextMonth,
        active: true,
      },
      {
        userId,
        accountId: account.id,
        categoryId: insuranceCat.id,
        amount: new Prisma.Decimal('15000'),
        frequency: Frequency.yearly,
        mode: RecurringMode.reminder_only,
        title: 'Insurance',
        note: 'Annual insurance premium',
        nextDate: nextYear,
        active: true,
      },
    ],
  });

  // Budgets: Food + Transport-oriented envelope for current month.
  const yearMonth = now.getFullYear() * 100 + (now.getMonth() + 1);
  await prisma.budget.createMany({
    data: [
      {
        userId,
        categoryId: dailyCat.id,
        amountLimit: new Prisma.Decimal('15000'),
        yearMonth,
      },
      {
        userId,
        categoryId: vehicleCat.id,
        amountLimit: new Prisma.Decimal('5000'),
        yearMonth,
      },
    ],
  });
  await prisma.account.update({
    where: { id: account.id },
    data: { balance: totalIncome.minus(totalExpense) },
  });
}

async function main() {
  const { demoUser } = await ensureUsers();
  await ensureWorkspace(demoUser.id, DEMO_NAME);
  await seedDemoData(demoUser.id);

  // eslint-disable-next-line no-console
  console.log(`Seed complete:`);
  // eslint-disable-next-line no-console
  console.log(`- Demo user: ${DEMO_EMAIL} / ${DEMO_PASSWORD}`);
  // eslint-disable-next-line no-console
  console.log(`- Admin user: ${ADMIN_EMAIL} / ${ADMIN_PASSWORD}`);
  // eslint-disable-next-line no-console
  console.log(`- Note: User model has no isAdmin field; admin access is represented via Admin table.`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
