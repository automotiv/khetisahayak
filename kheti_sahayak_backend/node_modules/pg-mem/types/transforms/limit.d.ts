import { IValue, _ISelection, _Transaction, _Explainer, _SelectExplanation, Stats, nil } from '../interfaces-private';
import { FilterBase } from './transform-base';
import { LimitStatement } from 'pgsql-ast-parser';
export declare function buildLimit(on: _ISelection, limit: LimitStatement): LimitFilter<any>;
declare class LimitFilter<T = any> extends FilterBase<T> {
    private selection;
    private take;
    private skip;
    get index(): null;
    entropy(t: _Transaction): number;
    hasItem(raw: T, t: _Transaction): boolean;
    constructor(selection: _ISelection<T>, take: IValue | nil, skip: IValue | nil);
    stats(t: _Transaction): Stats | null;
    enumerate(t: _Transaction): Iterable<T>;
    explain(e: _Explainer): _SelectExplanation;
}
export {};
//# sourceMappingURL=limit.d.ts.map