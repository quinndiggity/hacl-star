module Vale_check_sha_stdcall

open X64.Machine_s
open X64.Memory
open X64.Vale.State
open X64.Vale.Decls
open X64.Cpuidstdcall

val va_code_check_sha_stdcall: bool -> va_code

let va_code_check_sha_stdcall = va_code_check_sha_stdcall

let va_pre (va_b0:va_code) (va_s0:va_state) (win:bool) (stack_b:buffer64)
 = va_req_check_sha_stdcall va_b0 va_s0 win stack_b 

let va_post (va_b0:va_code) (va_s0:va_state) (va_sM:va_state) (va_fM:va_fuel) (win:bool)  (stack_b:buffer64)
 = va_ens_check_sha_stdcall va_b0 va_s0 win stack_b va_sM va_fM

val va_lemma_check_sha_stdcall(va_b0:va_code) (va_s0:va_state) (win:bool) (stack_b:buffer64)
: Ghost ((va_sM:va_state) * (va_fM:va_fuel))
  (requires va_pre va_b0 va_s0 win stack_b )
  (ensures (fun (va_sM, va_fM) -> va_post va_b0 va_s0 va_sM va_fM win stack_b ))

let va_lemma_check_sha_stdcall = va_lemma_check_sha_stdcall
