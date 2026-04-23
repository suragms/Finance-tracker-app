import { IsIn, IsNotEmpty, IsNumber, IsOptional, IsString, Min } from 'class-validator';

export class CreateTransactionDto {
  @IsIn(['income', 'expense', 'transfer'])
  type!: 'income' | 'expense' | 'transfer';

  @IsNumber()
  @Min(0.01)
  amount!: number;

  @IsOptional()
  @IsString()
  category_id?: string;

  @IsString()
  @IsNotEmpty()
  account_id!: string;

  @IsOptional()
  @IsString()
  to_account_id?: string;

  @IsOptional()
  @IsString()
  note?: string;

  @IsString()
  @IsNotEmpty()
  date!: string;
}
