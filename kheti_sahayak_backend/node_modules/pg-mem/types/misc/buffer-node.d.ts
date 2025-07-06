/// <reference types="node" />
export declare type TBuffer = Buffer;
export declare function bufToString(buf: TBuffer): string;
export declare function bufCompare(a: TBuffer, b: TBuffer): number;
export declare function bufFromString(str: string): Buffer;
export declare function isBuf(v: any): v is TBuffer;
export declare function bufClone(buf: TBuffer): TBuffer;
//# sourceMappingURL=buffer-node.d.ts.map