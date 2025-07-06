import { IValue, _Transaction, _Explainer, _SelectExplanation, Stats } from '../interfaces-private';
import { FilterBase } from './transform-base';
export declare class EqFilter<T = any> extends FilterBase<T> {
    private onValue;
    private equalsCst;
    private op;
    private matchNull;
    private index;
    private opDef;
    entropy(t: _Transaction): number;
    stats(t: _Transaction): Stats | null;
    hasItem(item: T, t: _Transaction): boolean;
    constructor(onValue: IValue<T>, equalsCst: any, op: 'eq' | 'neq', matchNull: boolean);
    enumerate(t: _Transaction): Iterable<T>;
    explain(e: _Explainer): _SelectExplanation;
}
//# sourceMappingURL=eq-filter.d.ts.map