import { IsEmail, IsIn, IsOptional, IsString, Matches, MinLength } from 'class-validator';

export class RegisterDto {
  @IsString()
  name!: string;

  /** Optional when using email + password (email is the primary identifier). */
  @IsOptional()
  @IsString()
  @MinLength(5)
  phone?: string;

  /** Optional when using mobile + password. */
  @IsOptional()
  @IsEmail()
  email?: string;

  @IsString()
  @MinLength(8, { message: 'Password must be at least 8 characters long' })
  @Matches(/((?=.*\d)|(?=.*\W+))(?![.\n])(?=.*[A-Z])(?=.*[a-z]).*$/, {
    message: 'Password is too weak. Must contain uppercase, lowercase, and a number or symbol.',
  })
  password!: string;

  @IsOptional()
  @IsIn(['INR', 'AED', 'SAR'])
  currency?: string;

  @IsOptional()
  @IsIn(['owner', 'manager', 'family'])
  role?: string;
}
