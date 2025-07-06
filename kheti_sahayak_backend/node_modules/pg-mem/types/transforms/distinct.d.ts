import { Expr } from 'pgsql-ast-parser';
import { IValue, Stats, _Explainer, _ISelection, _SelectExplanation, _Transaction } from '../interfaces-private';
import { FilterBase } from './transform-base';
export declare function buildDistinct(on: _ISelection, exprs?: Expr[]): Distinct<unknown>;
declare class Distinct<T> extends FilterBase<any> {
    private exprs;
    get index(): null;
    entropy(t: _Transaction): number;
    hasItem(raw: T, t: _Transaction): boolean;
    constructor(selection: _ISelection, exprs: ReadonlyArray<IValue>);
    stats(t: _Transaction): Stats | null;
    enumerate(t: _Transaction): Iterable<T>;
    explain(e: _Explainer): _SelectExplanation;
}
export {};
//# sourceMappingURL=distinct.d.ts.map