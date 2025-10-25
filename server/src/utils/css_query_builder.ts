type Predicate = string;

export class CssQueryBuilder {
  private base: string;
  private selectors: Predicate[][] = [[]]; // groups for OR logic
  private currentGroup = 0;

  constructor(base: string = '*') {
    this.base = base;
  }

  private addAttribute(attr: string, op: string, value: string) {
    const formatted = this.formatPredicate(attr, op, value);
    this.selectors[this.currentGroup]?.push(formatted);
    return this;
  }

  private formatPredicate(attr: string, op: string, value: string): string {
    switch (op) {
      case 'eq':
        return `[${attr}="${value}"]`;
      case 'like':
        return `[${attr}*="${value}"]`; // contains
      case 'startsWith':
        return `[${attr}^="${value}"]`;
      case 'endsWith':
        return `[${attr}$="${value}"]`;
      case 'not':
        return `:not([${attr}="${value}"])`;
      default:
        throw new Error(`Unknown operator: ${op}`);
    }
  }

  eq(attr: string, value: string) {
    return this.addAttribute(attr, 'eq', value);
  }

  like(attr: string, value: string) {
    return this.addAttribute(attr, 'like', value);
  }

  startsWith(attr: string, value: string) {
    return this.addAttribute(attr, 'startsWith', value);
  }

  endsWith(attr: string, value: string) {
    return this.addAttribute(attr, 'endsWith', value);
  }

  not(attr: string, value: string) {
    return this.addAttribute(attr, 'not', value);
  }

  or(callback: (qb: CssQueryBuilder) => CssQueryBuilder) {
    const newGroup = new CssQueryBuilder(this.base);
    callback(newGroup);
    if (newGroup.selectors.length !== 0) {
      this.selectors.push(newGroup.selectors[0]!);
    }
    return this;
  }

  build(): string {
    return this.selectors
      .map(group => this.base + group.join(''))
      .join(', ');
  }
}
