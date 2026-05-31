import { en } from './en.js';

type DeepValue<T> = T extends Record<string, unknown>
  ? { [K in keyof T]: DeepValue<T[K]> }[keyof T]
  : T;

type StringValue = DeepValue<typeof en>;

export function t(...path: string[]): StringValue {
  let current: unknown = en;
  for (const key of path) {
    if (current && typeof current === 'object' && key in current) {
      current = (current as Record<string, unknown>)[key];
    } else {
      return path.join('.') as unknown as StringValue;
    }
  }
  return current as StringValue;
}

export { en };
