import { IValue, _Transaction, _Explainer, _SelectExplanation, Stats } from '../interfaces-private';
import { FilterBase } from './transform-base';
export declare class IneqFilter<T = any> extends FilterBase<T> {
    private onValue;
    private op;
    private than;
    private index;
    private opDef;
    entropy(t: _Transaction): number;
    hasItem(item: T, t: _Transaction): boolean;
    constructor(onValue: IValue<T>, op: 'gt' | 'ge' | 'lt' | 'le', than: any);
    stats(t: _Transaction): Stats | null;
    enumerate(t: _Transaction): Iterable<T>;
    explain(e: _Explainer): _SelectExplanation;
}
//# sourceMappingURL=ineq-filter.d.ts.map