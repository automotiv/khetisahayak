import { IValue, _Transaction, _Explainer, _SelectExplanation, Stats } from '../interfaces-private';
import { FilterBase } from './transform-base';
export declare class InFilter<T = any> extends FilterBase<T> {
    private onValue;
    private elts;
    private index;
    entropy(t: _Transaction): number;
    hasItem(item: T, t: _Transaction): boolean;
    constructor(onValue: IValue<T>, elts: any[]);
    stats(t: _Transaction): Stats | null;
    enumerate(t: _Transaction): Iterable<T>;
    explain(e: _Explainer): _SelectExplanation;
}
//# sourceMappingURL=in-filter.d.ts.map