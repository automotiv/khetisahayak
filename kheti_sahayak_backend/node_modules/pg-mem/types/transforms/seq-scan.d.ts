import { IValue, _ISelection, _Transaction, _Explainer, _SelectExplanation, Stats } from '../interfaces-private';
import { FilterBase } from './transform-base';
export declare class SeqScanFilter<T = any> extends FilterBase<T> {
    private selection;
    private getter;
    get index(): null;
    entropy(t: _Transaction): number;
    hasItem(raw: T, t: _Transaction): boolean;
    constructor(selection: _ISelection<T>, getter: IValue<T>);
    stats(t: _Transaction): Stats | null;
    enumerate(t: _Transaction): Iterable<T>;
    explain(e: _Explainer): _SelectExplanation;
}
//# sourceMappingURL=seq-scan.d.ts.map