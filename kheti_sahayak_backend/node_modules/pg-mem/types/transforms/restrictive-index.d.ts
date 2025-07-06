import { _IIndex, IndexExpression, _Transaction, IndexKey, _Explainer, _IndexExplanation, IndexOp, _ISelection, Stats } from '../interfaces-private';
export declare class RestrictiveIndex<T> implements _IIndex<T> {
    private base;
    readonly filter: _ISelection<T>;
    constructor(base: _IIndex<T>, filter: _ISelection<T>);
    private match;
    get expressions(): IndexExpression[];
    stats(t: _Transaction, key?: IndexKey): Stats | null;
    iterateKeys(): null;
    eqFirst(rawKey: IndexKey, t: _Transaction): T | null;
    entropy(t: IndexOp): number;
    enumerate(op: IndexOp): Iterable<T>;
    explain(e: _Explainer): _IndexExplanation;
}
//# sourceMappingURL=restrictive-index.d.ts.map