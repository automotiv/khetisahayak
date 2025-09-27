import { _ISelection, _IIndex, _Transaction, _Explainer, _SelectExplanation, Stats, nil } from '../interfaces-private';
import { FilterBase } from './transform-base';
export declare class AndFilter<T = any> extends FilterBase<T> {
    private filters;
    get index(): _IIndex<T> | nil;
    private prevEntropy?;
    entropy(t: _Transaction): number;
    hasItem(value: T, t: _Transaction): boolean;
    constructor(filters: _ISelection<T>[]);
    private plan;
    stats(t: _Transaction): Stats | null;
    enumerate(t: _Transaction): Iterable<T>;
    explain(e: _Explainer): _SelectExplanation;
}
//# sourceMappingURL=and-filter.d.ts.map