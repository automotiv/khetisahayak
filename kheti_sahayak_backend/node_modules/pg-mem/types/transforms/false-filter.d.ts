import { _Explainer, _SelectExplanation, _Transaction, Stats } from '../interfaces-private';
import { FilterBase } from './transform-base';
export declare class FalseFilter<T = any> extends FilterBase<T> {
    get index(): null;
    entropy(): number;
    hasItem(): boolean;
    enumerate(): Iterable<T>;
    stats(t: _Transaction): Stats | null;
    explain(e: _Explainer): _SelectExplanation;
}
//# sourceMappingURL=false-filter.d.ts.map