import { IValue, _Transaction, _Explainer, _SelectExplanation, Stats } from '../interfaces-private';
import { FilterBase } from './transform-base';
export declare class BetweenFilter<T = any> extends FilterBase<T> {
    private onValue;
    private lo;
    private hi;
    private op;
    private opDef;
    entropy(t: _Transaction): number;
    constructor(onValue: IValue<T>, lo: any, hi: any, op: 'inside' | 'outside');
    hasItem(value: T, t: _Transaction): boolean;
    enumerate(t: _Transaction): Iterable<T>;
    stats(t: _Transaction): Stats | null;
    explain(e: _Explainer): _SelectExplanation;
}
//# sourceMappingURL=between-filter.d.ts.map