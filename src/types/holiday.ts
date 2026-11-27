import { ReactElement } from 'react';
import { MonthNumber } from './calendar';

export interface Holiday {
  id: string;
  name: string;
  month: MonthNumber;
  day: number;
  type: 'major' | 'minor' | 'period';
  duration?: number;
  icon?: () => ReactElement;
} 