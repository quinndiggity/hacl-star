module Hacl.Impl.Shift

open FStar.HyperStack.All
open Spec.Lib.IntBuf.Lemmas
open Spec.Lib.IntBuf
open Spec.Lib.IntTypes

open Hacl.Impl.Lib
open Hacl.Impl.Comparison
open Hacl.Impl.Addition

module Buffer = Spec.Lib.IntBuf

(* This file will be removed *)

inline_for_extraction
let bn_tbit = u64 0x8000000000000000

val bn_lshift1_:
  #aLen:size_nat -> aaLen:size_t{v aaLen == aLen} ->
  a:lbignum aLen -> carry:uint64 -> i:size_t{v i <= aLen} ->
  res:lbignum aLen -> Stack unit
  (requires (fun h -> live h a /\ live h res))
  (ensures (fun h0 _ h1 -> preserves_live h0 h1 /\ modifies1 res h0 h1))
  [@"c_inline"]
let rec bn_lshift1_ #aLen aaLen a carry i res =
  if (i <. aaLen) then begin
    let tmp = a.(i) in
    res.(i) <- (shift_left #U64 tmp (u32 1)) |. carry;
    let carry = if (eq_u64 (logand #U64 tmp bn_tbit) bn_tbit) then u64 1 else u64 0 in
    bn_lshift1_ aaLen a carry (add #SIZE i (size 1)) res
  end

// res = a << 1
val bn_lshift1:
  #aLen:size_nat -> aaLen:size_t{v aaLen == aLen} ->
  a:lbignum aLen -> res:lbignum aLen -> Stack unit
  (requires (fun h -> live h a /\ live h res))
  (ensures (fun h0 _ h1 -> preserves_live h0 h1 /\ modifies1 res h0 h1))
  [@"c_inline"]
let bn_lshift1 #aLen aaLen a res = bn_lshift1_ aaLen a (u64 0) (size 0) res

val bn_pow2_mod_n_:
  #aLen:size_nat -> #rLen:size_nat{aLen < rLen} ->
  aaLen:size_t{v aaLen == aLen} -> a:lbignum aLen ->
  i:size_t -> p:size_t ->
  rrLen:size_t{v rrLen == rLen} -> res:lbignum rLen ->
  Stack unit
    (requires (fun h -> live h a /\ live h res /\ disjoint res a))
    (ensures (fun h0 _ h1 -> preserves_live h0 h1 /\ modifies1 res h0 h1))
  [@"c_inline"]
let rec bn_pow2_mod_n_ #aLen #rLen aaLen a i p rrLen res =
  if (i <. p) then begin
    bn_lshift1 rrLen res res;
    (if not (bn_is_less rrLen res aaLen a) then
      let _ = bn_sub rrLen res aaLen a res in ());
    bn_pow2_mod_n_ aaLen a (add #SIZE i (size 1)) p rrLen res
  end

// res = 2 ^^ p % a
val bn_pow2_mod_n:
  #aLen:size_nat -> aaLen:size_t{v aaLen == aLen /\ aLen + 1 < max_size_t} ->
  aBits:size_t -> a:lbignum aLen ->
  p:size_t{v aBits < v p} ->
  res:lbignum aLen ->
  Stack unit
    (requires (fun h -> live h a /\ live h res /\ disjoint res a))
    (ensures (fun h0 _ h1 -> preserves_live h0 h1 /\ modifies1 res h0 h1))
  [@"c_inline"]
let bn_pow2_mod_n #aLen aaLen aBits a p res =
  let rLen = add #SIZE aaLen (size 1) in
  alloc #uint64 #unit #(v rLen) rLen (u64 0) [BufItem a] [BufItem res]
  (fun h0 _ h1 -> True)
  (fun tmp ->
    assume (v aBits / 64 < v rLen);
    bn_set_bit rLen tmp aBits;
    let _ = bn_sub rLen tmp aaLen a tmp in // tmp = tmp - a
    bn_pow2_mod_n_ #aLen #(v rLen) aaLen a aBits p rLen tmp;
    let tmp' = Buffer.sub #uint64 #(v rLen) #aLen tmp (size 0) aaLen in
    copy aaLen tmp' res
  )
