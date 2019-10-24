(*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *)

(* Properties of the llair model *)

open HolKernel boolLib bossLib Parse;
open arithmeticTheory integerTheory integer_wordTheory wordsTheory listTheory;
open pred_setTheory finite_mapTheory;
open settingsTheory miscTheory llairTheory;

new_theory "llair_prop";

numLib.prefer_num ();

Theorem i2n_n2i:
  !n size. 0 < size ⇒ (nfits n size ⇔ (i2n (n2i n size) = n))
Proof
  rw [nfits_def, n2i_def, i2n_def] >> rw []
  >- intLib.COOPER_TAC
  >- (
    `2 ** size ≤ n` by intLib.COOPER_TAC >> simp [INT_SUB] >>
    Cases_on `n = 0` >> fs [] >>
    `n - 2 ** size < n` suffices_by intLib.COOPER_TAC >>
    irule SUB_LESS >> simp [])
  >- (
    `2 ** (size - 1) < 2 ** size` suffices_by intLib.COOPER_TAC >>
    fs [])
QED

Theorem n2i_i2n:
  !i size. 0 < size ⇒ (ifits i size ⇔ (n2i (i2n (IntV i size)) size) = IntV i size)
Proof
  rw [ifits_def, n2i_def, i2n_def] >> rw [] >> fs []
  >- (
    eq_tac >> rw []
    >- (
      simp [intLib.COOPER_PROVE ``∀(x:int) y z. x - y = z ⇔ x = y + z``] >>
      `2 ** (size - 1) < 2 ** size` suffices_by intLib.COOPER_TAC >>
      fs [INT_OF_NUM])
    >- (
      fs [intLib.COOPER_PROVE ``∀(x:int) y z. x - y = z ⇔ x = y + z``] >>
      fs [INT_OF_NUM] >>
      `?j. i = -j` by intLib.COOPER_TAC >> rw [] >> fs [] >>
      qpat_x_assum `_ ≤ Num _` mp_tac >>
      fs [GSYM INT_OF_NUM] >>
      ASM_REWRITE_TAC [GSYM INT_LE] >> rw [] >>
      `2 ** size = 2 * 2 ** (size - 1)` by rw [GSYM EXP, ADD1] >> fs [] >>
      intLib.COOPER_TAC)
    >- intLib.COOPER_TAC)
  >- (
    eq_tac >> rw []
    >- intLib.COOPER_TAC
    >- intLib.COOPER_TAC >>
    `0 ≤ i` by intLib.COOPER_TAC >>
    fs [GSYM INT_OF_NUM] >>
    `&(2 ** size) = 0` by intLib.COOPER_TAC >>
    fs [])
  >- (
    eq_tac >> rw []
    >- (
      `2 ** size = 2 * 2 ** (size - 1)` by rw [GSYM EXP, ADD1] >> fs [] >>
      intLib.COOPER_TAC)
    >- intLib.COOPER_TAC
    >- intLib.COOPER_TAC)
  >- intLib.COOPER_TAC
QED

Theorem w2n_i2n:
  ∀w. w2n (w : 'a word) = i2n (IntV (w2i w) (dimindex (:'a)))
Proof
  rw [i2n_def] >> Cases_on `w` >> fs []
  >- (
    `INT_MIN (:α) ≤ n`
    by (
      fs [w2i_def] >> rw [] >>
      BasicProvers.EVERY_CASE_TAC >> fs [word_msb_n2w_numeric] >>
      rfs []) >>
    rw [w2i_n2w_neg, dimword_def, int_arithTheory.INT_NUM_SUB])
  >- (
    `n < INT_MIN (:'a)`
    by (
      fs [w2i_def] >> rw [] >>
      BasicProvers.EVERY_CASE_TAC >> fs [word_msb_n2w_numeric] >>
      rfs []) >>
    rw [w2i_n2w_pos])
QED

Theorem w2i_n2w:
  ∀n. n < dimword (:'a) ⇒ IntV (w2i (n2w n : 'a word)) (dimindex (:'a)) = n2i n (dimindex (:'a))
Proof
  rw [n2i_def]
  >- (
    qspec_then `n` mp_tac w2i_n2w_neg >>
    fs [dimword_def, INT_MIN_def] >> rw [GSYM INT_SUB])
  >- (irule w2i_n2w_pos >> rw [INT_MIN_def])
QED

Theorem eval_exp_ignores_lem:
  ∀s1 e v. eval_exp s1 e v ⇒ ∀s2. s1.locals = s2.locals ⇒ eval_exp s2 e v
Proof
  ho_match_mp_tac eval_exp_ind >>
  rw [] >> simp [Once eval_exp_cases] >>
  TRY (qexists_tac `vals` >> rw [] >> fs [LIST_REL_EL_EQN] >> NO_TAC) >>
  TRY (fs [LIST_REL_EL_EQN] >> NO_TAC) >>
  metis_tac []
QED

Theorem eval_exp_ignores:
  ∀s1 e v s2. s1.locals = s2.locals ⇒ (eval_exp s1 e v ⇔ eval_exp s2 e v)
Proof
  metis_tac [eval_exp_ignores_lem]
QED

Definition exp_uses_def:
  (exp_uses (Var x) = {x}) ∧
  (exp_uses Nondet = {}) ∧
  (exp_uses (Label _) = {}) ∧
  (exp_uses (Splat e1 e2) = exp_uses e1 ∪ exp_uses e2) ∧
  (exp_uses (Memory e1 e2) = exp_uses e1 ∪ exp_uses e2) ∧
  (exp_uses (Concat es) = bigunion (set (map exp_uses es))) ∧
  (exp_uses (Integer _ _) = {}) ∧
  (exp_uses (Eq e1 e2) = exp_uses e1 ∪ exp_uses e2) ∧
  (exp_uses (Lt e1 e2) = exp_uses e1 ∪ exp_uses e2) ∧
  (exp_uses (Ult e1 e2) = exp_uses e1 ∪ exp_uses e2) ∧
  (exp_uses (Sub _ e1 e2) = exp_uses e1 ∪ exp_uses e2) ∧
  (exp_uses (Record es) = bigunion (set (map exp_uses es))) ∧
  (exp_uses (Select e1 e2) = exp_uses e1 ∪ exp_uses e2) ∧
  (exp_uses (Update e1 e2 e3) = exp_uses e1 ∪ exp_uses e2 ∪ exp_uses e3) ∧
  (exp_uses (Convert _ _ _ e) = exp_uses e)
Termination
  WF_REL_TAC `measure exp_size` >> rw [] >>
  Induct_on `es` >> rw [exp_size_def] >> res_tac >> rw []
End

Theorem eval_exp_ignores_unused_lem:
  ∀s1 e v.
    eval_exp s1 e v ⇒
    ∀s2. DRESTRICT s1.locals (exp_uses e) = DRESTRICT s2.locals (exp_uses e) ⇒
    eval_exp s2 e v
Proof
  ho_match_mp_tac eval_exp_ind >>
  rw [exp_uses_def] >> simp [Once eval_exp_cases]
  >- (
    fs [DRESTRICT_EQ_DRESTRICT, EXTENSION, FDOM_DRESTRICT] >>
    imp_res_tac FLOOKUP_SUBMAP >>
    fs [FLOOKUP_DRESTRICT]) >>
  fs [drestrict_union_eq]
  >- metis_tac []
  >- metis_tac []
  >- (
    rpt (pop_assum mp_tac) >>
    qid_spec_tac `vals` >>
    Induct_on `es` >> rw [] >> Cases_on `vals` >> rw [PULL_EXISTS] >> fs [] >>
    rw [] >> fs [drestrict_union_eq] >>
    rename [`v1++flat vs`] >>
    first_x_assum (qspec_then `vs` mp_tac) >> rw [] >>
    qexists_tac `v1 :: vals'` >> rw [])
  >- metis_tac []
  >- metis_tac []
  >- metis_tac []
  >- metis_tac []
  >- (
    rpt (pop_assum mp_tac) >>
    qid_spec_tac `vals` >>
    Induct_on `es` >> rw [] >> fs [drestrict_union_eq])
  >- metis_tac []
  >- metis_tac []
  >- metis_tac []
  >- metis_tac []
QED

Theorem eval_exp_ignores_unused:
  ∀s1 e v s2. DRESTRICT s1.locals (exp_uses e) = DRESTRICT s2.locals (exp_uses e) ⇒ (eval_exp s1 e v ⇔ eval_exp s2 e v)
Proof
  metis_tac [eval_exp_ignores_unused_lem]
QED

export_theory ();
