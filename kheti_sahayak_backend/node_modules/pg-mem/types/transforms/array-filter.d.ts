import { FilterBase } from './transform-base';
import { _ISelection, _Explainer, _SelectExplanation, _Transaction, Stats } from '../interfaces-private';
export declare class ArrayFilter<T = any> extends FilterBase<T> {
    rows: T[];
    get index(): null;
    entropy(): number;
    hasItem(raw: T): boolean;
    getIndex(): null;
    constructor(fromTable: _ISelection<T>, rows: T[]);
    enumerate(): Iterable<T>;
    stats(t: _Transaction): Stats | null;
    explain(e: _Explainer): _SelectExplanation;
}
//# sourceMappingURL=array-filter.d.ts.map