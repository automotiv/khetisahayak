import { _ISelection, _Transaction, _Explainer, _SelectExplanation, Stats } from '../interfaces-private';
import { FilterBase } from './transform-base';
export declare class OrFilter<T = any> extends FilterBase<T> {
    private left;
    private right;
    entropy(t: _Transaction): number;
    hasItem(value: T, t: _Transaction): boolean;
    constructor(left: _ISelection<T>, right: _ISelection<T>);
    stats(t: _Transaction): Stats | null;
    enumerate(t: _Transaction): Iterable<T>;
    explain(e: _Explainer): _SelectExplanation;
}
//# sourceMappingURL=or-filter.d.ts.map