import { IValue, _Transaction, _Explainer, _SelectExplanation, Stats } from '../interfaces-private';
import { FilterBase } from './transform-base';
export declare class StartsWithFilter<T = any> extends FilterBase<T> {
    private onValue;
    private startWith;
    get index(): null;
    entropy(t: _Transaction): number;
    hasItem(item: T, t: _Transaction): boolean;
    constructor(onValue: IValue<T>, startWith: string);
    stats(t: _Transaction): Stats | null;
    enumerate(t: _Transaction): Iterable<T>;
    explain(e: _Explainer): _SelectExplanation;
}
//# sourceMappingURL=startswith-filter.d.ts.map