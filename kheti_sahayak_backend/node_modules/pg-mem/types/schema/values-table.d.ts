import { nil, Schema } from '../interfaces';
import { _Transaction } from '../interfaces-private';
import { Expr } from 'pgsql-ast-parser';
import { ReadOnlyTable } from './readonly-table';
export declare class ValuesTable extends ReadOnlyTable {
    private symbol;
    _schema: Schema;
    private assignments;
    entropy(t: _Transaction): number;
    enumerate(t: _Transaction): Iterable<any>;
    hasItem(value: any, t: _Transaction): boolean;
    constructor(alias: string, items: Expr[][], columnNames: string[] | nil, acceptDefault?: boolean);
}
//# sourceMappingURL=values-table.d.ts.map