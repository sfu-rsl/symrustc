#include <Runtime.h>

#ifndef NDEBUG
#include <chrono>
#endif

#include <iostream>

#include "Config.h"
#include "LibcWrappers.h"
#include "Shadow.h"

/*
 * Initialization
 */
void _sym_initialize(void) {
  loadConfig();
  initLibcWrappers();
  
  std::cerr << "This is SymCC running with the NOOP backend." << std::endl;
  std::cerr << "The runtime is not going to do anything." << std::endl;
}

/*
 * Construction of simple values
 */
SymExpr _sym_build_integer(uint64_t value, uint8_t bits) { return NULL; }
SymExpr _sym_build_integer128(uint64_t high, uint64_t low) { return NULL; }
SymExpr _sym_build_float(double value, int is_double) { return NULL; }
SymExpr _sym_build_null_pointer(void) { return NULL; }
SymExpr _sym_build_true(void) { return NULL; }
SymExpr _sym_build_false(void) { return NULL; }
SymExpr _sym_build_bool(bool value) { return NULL; }

/*
 * Integer arithmetic and shifts
 */
SymExpr _sym_build_neg(SymExpr expr) { return NULL; }
SymExpr _sym_build_add(SymExpr a, SymExpr b) { return NULL; }
SymExpr _sym_build_sub(SymExpr a, SymExpr b) { return NULL; }
SymExpr _sym_build_mul(SymExpr a, SymExpr b) { return NULL; }
SymExpr _sym_build_unsigned_div(SymExpr a, SymExpr b) { return NULL; }
SymExpr _sym_build_signed_div(SymExpr a, SymExpr b) { return NULL; }
SymExpr _sym_build_unsigned_rem(SymExpr a, SymExpr b) { return NULL; }
SymExpr _sym_build_signed_rem(SymExpr a, SymExpr b) { return NULL; }
SymExpr _sym_build_shift_left(SymExpr a, SymExpr b) { return NULL; }
SymExpr _sym_build_logical_shift_right(SymExpr a, SymExpr b) { return NULL; }
SymExpr _sym_build_arithmetic_shift_right(SymExpr a, SymExpr b) { return NULL; }
SymExpr _sym_build_funnel_shift_left(SymExpr a, SymExpr b, SymExpr c) {
  return NULL;
}
SymExpr _sym_build_funnel_shift_right(SymExpr a, SymExpr b, SymExpr c) {
  return NULL;
}
SymExpr _sym_build_abs(SymExpr expr) { return NULL; }

/*
 * Arithmetic with overflow
 */
SymExpr _sym_build_add_overflow(SymExpr a, SymExpr b, bool is_signed,
                                bool little_endian) {
  return NULL;
}
SymExpr _sym_build_sub_overflow(SymExpr a, SymExpr b, bool is_signed,
                                bool little_endian) {
  return NULL;
}
SymExpr _sym_build_mul_overflow(SymExpr a, SymExpr b, bool is_signed,
                                bool little_endian) {
  return NULL;
}

/*
 * Saturating integer arithmetic and shifts
 */
SymExpr _sym_build_sadd_sat(SymExpr a, SymExpr b) { return NULL; }
SymExpr _sym_build_uadd_sat(SymExpr a, SymExpr b) { return NULL; }
SymExpr _sym_build_ssub_sat(SymExpr a, SymExpr b) { return NULL; }
SymExpr _sym_build_usub_sat(SymExpr a, SymExpr b) { return NULL; }
SymExpr _sym_build_sshl_sat(SymExpr a, SymExpr b) { return NULL; }
SymExpr _sym_build_ushl_sat(SymExpr a, SymExpr b) { return NULL; }

/*
 * Floating-point arithmetic and shifts
 */
SymExpr _sym_build_fp_add(SymExpr a, SymExpr b) { return NULL; }
SymExpr _sym_build_fp_sub(SymExpr a, SymExpr b) { return NULL; }
SymExpr _sym_build_fp_mul(SymExpr a, SymExpr b) { return NULL; }
SymExpr _sym_build_fp_div(SymExpr a, SymExpr b) { return NULL; }
SymExpr _sym_build_fp_rem(SymExpr a, SymExpr b) { return NULL; }
SymExpr _sym_build_fp_abs(SymExpr a) { return NULL; }
SymExpr _sym_build_fp_neg(SymExpr a) { return NULL; }

/*
 * Boolean operations
 */
SymExpr _sym_build_not(SymExpr expr) { return NULL; }
SymExpr _sym_build_signed_less_than(SymExpr a, SymExpr b) { return NULL; }
SymExpr _sym_build_signed_less_equal(SymExpr a, SymExpr b) { return NULL; }
SymExpr _sym_build_signed_greater_than(SymExpr a, SymExpr b) { return NULL; }
SymExpr _sym_build_signed_greater_equal(SymExpr a, SymExpr b) { return NULL; }
SymExpr _sym_build_unsigned_less_than(SymExpr a, SymExpr b) { return NULL; }
SymExpr _sym_build_unsigned_less_equal(SymExpr a, SymExpr b) { return NULL; }
SymExpr _sym_build_unsigned_greater_than(SymExpr a, SymExpr b) { return NULL; }
SymExpr _sym_build_unsigned_greater_equal(SymExpr a, SymExpr b) { return NULL; }
SymExpr _sym_build_equal(SymExpr a, SymExpr b) { return NULL; }
SymExpr _sym_build_not_equal(SymExpr a, SymExpr b) { return NULL; }
SymExpr _sym_build_bool_and(SymExpr a, SymExpr b) { return NULL; }
SymExpr _sym_build_and(SymExpr a, SymExpr b) { return NULL; }
SymExpr _sym_build_bool_or(SymExpr a, SymExpr b) { return NULL; }
SymExpr _sym_build_or(SymExpr a, SymExpr b) { return NULL; }
SymExpr _sym_build_bool_xor(SymExpr a, SymExpr b) { return NULL; }
SymExpr _sym_build_xor(SymExpr a, SymExpr b) { return NULL; }
SymExpr _sym_build_ite(SymExpr cond, SymExpr a, SymExpr b) { return NULL; }

SymExpr _sym_build_float_ordered_greater_than(SymExpr a, SymExpr b) {
  return NULL;
}
SymExpr _sym_build_float_ordered_greater_equal(SymExpr a, SymExpr b) {
  return NULL;
}
SymExpr _sym_build_float_ordered_less_than(SymExpr a, SymExpr b) {
  return NULL;
}
SymExpr _sym_build_float_ordered_less_equal(SymExpr a, SymExpr b) {
  return NULL;
}
SymExpr _sym_build_float_ordered_equal(SymExpr a, SymExpr b) { return NULL; }
SymExpr _sym_build_float_ordered_not_equal(SymExpr a, SymExpr b) {
  return NULL;
}
SymExpr _sym_build_float_ordered(SymExpr a, SymExpr b) { return NULL; }
SymExpr _sym_build_float_unordered(SymExpr a, SymExpr b) { return NULL; }
SymExpr _sym_build_float_unordered_greater_than(SymExpr a, SymExpr b) {
  return NULL;
}
SymExpr _sym_build_float_unordered_greater_equal(SymExpr a, SymExpr b) {
  return NULL;
}
SymExpr _sym_build_float_unordered_less_than(SymExpr a, SymExpr b) {
  return NULL;
}
SymExpr _sym_build_float_unordered_less_equal(SymExpr a, SymExpr b) {
  return NULL;
}
SymExpr _sym_build_float_unordered_equal(SymExpr a, SymExpr b) { return NULL; }
SymExpr _sym_build_float_unordered_not_equal(SymExpr a, SymExpr b) {
  return NULL;
}

/*
 * Casts
 */
SymExpr _sym_build_sext(SymExpr expr, uint8_t bits) { return NULL; }
SymExpr _sym_build_zext(SymExpr expr, uint8_t bits) { return NULL; }
SymExpr _sym_build_trunc(SymExpr expr, uint8_t bits) { return NULL; }
SymExpr _sym_build_bswap(SymExpr expr) { return NULL; }
SymExpr _sym_build_int_to_float(SymExpr value, int is_double, int is_signed) {
  return NULL;
}
SymExpr _sym_build_float_to_float(SymExpr expr, int to_double) { return NULL; }
SymExpr _sym_build_bits_to_float(SymExpr expr, int to_double) { return NULL; }
SymExpr _sym_build_float_to_bits(SymExpr expr) { return NULL; }
SymExpr _sym_build_float_to_signed_integer(SymExpr expr, uint8_t bits) {
  return NULL;
}
SymExpr _sym_build_float_to_unsigned_integer(SymExpr expr, uint8_t bits) {
  return NULL;
}
SymExpr _sym_build_bool_to_bit(SymExpr expr) { return NULL; }
SymExpr _sym_build_bit_to_bool(SymExpr expr) { return NULL; }

/*
 * Bit-array helpers
 */
SymExpr _sym_concat_helper(SymExpr a, SymExpr b) { return NULL; }
SymExpr _sym_extract_helper(SymExpr expr, size_t first_bit, size_t last_bit) {
  return NULL;
}
size_t _sym_bits_helper(SymExpr expr) { return 0; }

/*
 * Function-call helpers
 */
void _sym_set_parameter_expression(uint8_t index, SymExpr expr) { return; }
SymExpr _sym_get_parameter_expression(uint8_t index) { return NULL; }
void _sym_set_return_expression(SymExpr expr) { return; }
SymExpr _sym_get_return_expression(void) { return NULL; }

/*
 * Constraint handling
 */
void _sym_push_path_constraint(SymExpr constraint, int taken,
                               uintptr_t site_id) {
  return;
}
SymExpr _sym_get_input_byte(size_t offset, uint8_t concrete_value) {
  return NULL;
}
void _sym_make_symbolic(void *data, size_t byte_length,
                        size_t input_offset) {
  return;
}

/*
 * Memory management
 */
SymExpr _sym_read_memory(uint8_t *addr, size_t length, bool little_endian) {
  return NULL;
}
void _sym_write_memory(uint8_t *addr, size_t length, SymExpr expr,
                       bool little_endian) {
  return;
}
void _sym_memcpy(uint8_t *dest, const uint8_t *src, size_t length) { return; }
void _sym_memset(uint8_t *memory, SymExpr value, size_t length) { return; }
void _sym_memmove(uint8_t *dest, const uint8_t *src, size_t length) { return; }
SymExpr _sym_build_zero_bytes(size_t length) { return NULL; }
SymExpr _sym_build_insert(SymExpr target, SymExpr to_insert, uint64_t offset,
                          bool little_endian) {
  return NULL;
}
SymExpr _sym_build_extract(SymExpr expr, uint64_t offset, uint64_t length,
                           bool little_endian) {
  return NULL;
}

/*
 * Call-stack tracing
 */
void _sym_notify_call(uintptr_t site_id) { return; }
void _sym_notify_ret(uintptr_t site_id) { return; }
void _sym_notify_basic_block(uintptr_t site_id) { return; }

/*
 * Debugging
 */
const char *_sym_expr_to_string(SymExpr expr) {
  return "";
} // statically allocated
bool _sym_feasible(SymExpr expr) { return false; }

/*
 * Garbage collection
 */
void _sym_register_expression_region(SymExpr *start, size_t length) { return; }
void _sym_collect_garbage(void) { return; }

/*
 * User-facing functionality
 *
 * These are the only functions in the interface that we expect to be called by
 * users (i.e., calls to it aren't auto-generated by our compiler pass).
 */
void symcc_make_symbolic(void *start, size_t byte_length) { return; }
typedef void (*TestCaseHandler)(const void *, size_t);
void symcc_set_test_case_handler(TestCaseHandler handler) { return; }
