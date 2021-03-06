From mathcomp Require Import all_ssreflect all_fingroup all_algebra.
From mathcomp Require Import all_solvable all_field polyrcf.
From Abel Require Import various classic_ext map_gal algR.
From Abel Require Import diag char0 cyclotomic_ext galmx real_closed_ext.

(*****************************************************************************)
(* We work inside a enclosing splittingFieldType L over a base field F0      *)
(*                                                                           *)
(*     radical U x n := x is a radical element of degree n over U            *)
(*    pradical U x p := x is a radical element of prime degree p over U      *)
(*   r.-tower U e pw := e is a chain of elements of L such that              *)
(*                      forall i, r <<U & take i e>> e`_i pw`_i              *)
(*        r.-ext U V := there exists e and pw such that <<U & e>> = V        *)
(*                      and r.-tower U e p  w.                               *)
(* solvable_by r E F := there is a field K, such that F <= K and r.-ext E K  *)
(*                      if p has roots rs, solvable_by radicals E <<E, rs>>  *)
(* solvable_ext_poly p := the Galois group of p is solvable in any splitting *)
(*                      field L for p. (i.e. p has roots rs in a splitting   *)
(*                      then, 'Gal(<<1 & rs>>/1) is solbable.                *)
(*                      This is equivalent to general classical existence    *)
(*                      or constructive existence over rat, of a splitting   *)
(*                      field for p, in which its  Galois group is solvable  *)
(* solvable_by_radical_poly p := solvable_by radical 1 <<1; rs>> in L        *)
(*                      L being any splitting field L where p has roots rs   *)
(*                      and which contains a n nth primitive root of unity,  *)
(*                      (we me make n explicit in ext_solvable_by_radical)   *)
(*                      This is equivalent to general classical existence    *)
(*                      or constructive existence over rat, of a splitting   *)
(*                      field for p, in which the roots of p are rs, and in  *)
(*                      which solvable_by radical 1 <<1; rs>> in L.          *)
(*****************************************************************************)

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Import GRing.Theory.

Local Open Scope ring_scope.

Local Notation "p ^^ f" := (map_poly f p)
  (at level 30, f at level 30, format "p  ^^  f").
Local Notation "2" := 2%:R : ring_scope.
Local Notation "3" := 3%:R : ring_scope.
Local Notation "4" := 4%:R : ring_scope.
Local Notation "5" := 5%:R : ring_scope.

Section RadicalExtension.

Variables (F0 : fieldType) (L : splittingFieldType F0).
Hypothesis (charL : [char L] =i pred0).

Section Defs.

Implicit Types (U V : {vspace L}).

Definition radical U x n  := [&& (n > 0)%N & x ^+ n \in U].
Definition pradical U x p := [&& prime p & x ^+ p \in U].

Lemma radicalP U x n : reflect  [/\ (n > 0)%N & x ^+ n \in U]
                                [&& (n > 0)%N & x ^+ n \in U].
Proof. exact/andP. Qed.

Lemma pradicalP U x p : reflect [/\ prime p & x ^+ p \in U]
                                [&& prime p & x ^+ p \in U].
Proof. exact/andP. Qed.

Implicit Types r : {vspace L} -> L -> nat -> bool.

Definition tower r n U (e : n.-tuple L) (pw : n.-tuple nat) :=
  [forall i : 'I_n, r << U & take i e >>%VS (tnth e i) (tnth pw i)].

Lemma towerP r n U (e : n.-tuple L) (pw : n.-tuple nat) :
  reflect (forall i : 'I_n, r << U & take i e >>%VS (tnth e i) (tnth pw i))
          (tower r U e pw).
Proof. exact/forallP. Qed.

Local Notation "r .-tower" := (@tower r _)
  (at level 2, format "r .-tower") : ring_scope.

Record ext_data := ExtData { ext_size : nat;
                             ext_ep : ext_size.-tuple L;
                             ext_pw : ext_size.-tuple nat }.
Arguments ExtData [ext_size].

Definition trivExt := ExtData [tuple] [tuple].

Definition extension_of r U V :=
  exists2 e : ext_data,
    r.-tower U (ext_ep e) (ext_pw e)
    & << U & ext_ep e >>%VS = V.

Local Notation "r .-ext" := (extension_of r)
  (at level 2, format "r .-ext") : ring_scope.

Definition solvable_by r (U V : {vspace L}) :=
  exists2 E : {subfield L}, r.-ext U E & (V <= E)%VS.

End Defs.

Local Notation "r .-tower" := (@tower r _)
  (at level 2, format "r .-tower") : ring_scope.
Local Notation "r .-ext" := (extension_of r)
  (at level 2, format "r .-ext") : ring_scope.

Section Properties.

Implicit Types r : {vspace L} -> L -> nat -> bool.
Implicit Types (U V : {subfield L}).

Lemma rext_refl r (E : {subfield L}) : r.-ext E E.
Proof. by exists trivExt; rewrite ?Fadjoin_nil//=; apply/towerP => -[]. Qed.

Lemma rext_r r n (U : {subfield L}) x : r U x n -> r.-ext U << U; x >>%VS.
Proof.
move=> rUxn; exists (ExtData [tuple x] [tuple n]); last by rewrite adjoin_seq1.
by apply/towerP => /= i; rewrite ord1/= !tnth0 Fadjoin_nil.
Qed.

Lemma rext_trans r (F E K : {subfield L}) :
  r.-ext E F -> r.-ext F K -> r.-ext E K.
Proof.
move=> [[/= n1 e1 pw1] Ee FE] [[/= n2 e2 pw2] Fe KE].
exists (ExtData [tuple of e1 ++ e2] [tuple of pw1 ++ pw2]) => /=; last first.
  by rewrite adjoin_cat FE.
apply/towerP => /= i; case: (unsplitP i) => [j eq_ij|k eq_i_n1Dk].
- rewrite eq_ij !tnth_lshift takel_cat /=; last first.
    by rewrite size_tuple ltnW.
  by move/forallP/(_ j): Ee.
- rewrite eq_i_n1Dk take_cat size_tuple ltnNge leq_addr /= addKn.
  by rewrite adjoin_cat FE !tnth_rshift; move/forallP/(_ k): Fe.
Qed.

Lemma rext_r_trans r n (E F K : {subfield L}) x :
  r.-ext E F -> r F x n -> r.-ext E << F; x>>%VS.
Proof. by move=> rEF /rext_r; apply: rext_trans. Qed.

Lemma rext_subspace r E F : r.-ext E F -> (E <= F)%VS.
Proof. by case=> [[/= n e pw] _ <-]; apply: subv_adjoin_seq. Qed.

Lemma solvable_by_radicals_radicalext (E F : {subfield L}) :
  radical.-ext E F -> solvable_by radical E F.
Proof. by move=> extEF; exists F. Qed.

Lemma radical_Fadjoin (n : nat) (x : L) (E : {subfield L}) :
  (0 < n)%N -> x ^+ n \in E -> radical E x n.
Proof. by move=> ? ?; apply/radicalP. Qed.

Lemma pradical_Fadjoin (n : nat) (x : L) (E : {subfield L}) :
  prime n -> x ^+ n \in E -> pradical E x n.
Proof. by move=> ? ?; apply/pradicalP. Qed.

Lemma radical_ext_Fadjoin (n : nat) (x : L) (E : {subfield L}) :
  (0 < n)%N -> x ^+ n \in E -> radical.-ext E <<E; x>>%VS.
Proof. by move=> n_gt0 xnE; apply/rext_r/(radical_Fadjoin n_gt0 xnE). Qed.

Lemma pradical_ext_Fadjoin (p : nat) (x : L) (E : {subfield L}) :
  prime p -> x ^+ p \in E -> pradical.-ext E <<E; x>>%AS.
Proof. by move=> p_prime Exn; apply/rext_r/(pradical_Fadjoin p_prime Exn). Qed.

Lemma pradicalext_radical n (x : L) (E : {subfield L}) :
  radical E x n -> pradical.-ext E << E; x >>%VS.
Proof.
move=> /radicalP[n_gt0 xnE]; have [k] := ubnP n.
elim: k => // k IHk in n x E n_gt0 xnE *; rewrite ltnS => lenk.
have [prime_n|primeN_n] := boolP (prime n).
  by apply: (@pradical_ext_Fadjoin n).
case/boolP: (2 <= n)%N; last first.
  case: n {lenk primeN_n} => [|[]]// in xnE n_gt0 * => _.
  suff ->:  <<E; x>>%VS = E by apply: rext_refl.
  by rewrite (Fadjoin_idP _).
move: primeN_n => /primePn[|[d /andP[d_gt1 d_ltn] dvd_dn n_gt1]].
  by case: ltngtP.
have [m n_eq_md]: {k : nat | n = (k * d)%N}.
  by exists (n %/ d)%N; rewrite [LHS](divn_eq _ d) (eqP dvd_dn) addn0.
have m_gt0 : (m > 0)%N.
  by move: n_gt0; rewrite !lt0n n_eq_md; apply: contra_neq => ->.
apply: (@rext_trans _ <<E; x ^+ d>>) => //.
  apply: (@IHk m (x ^+ d)) => //.
    by rewrite -exprM mulnC -n_eq_md//.
  by rewrite (leq_trans _ lenk)// n_eq_md ltn_Pmulr.
suff -> : <<E; x>>%AS = <<<<E; x ^+ d>>; x>>%AS.
  apply: (IHk d) => //.
  - by rewrite (leq_trans _ d_gt1)//.
  - by rewrite memv_adjoin.
  - by rewrite (leq_trans _ lenk).
apply/val_inj; rewrite /= adjoinC [<<_; x ^+ d>>%VS](Fadjoin_idP _)//.
by rewrite rpredX// memv_adjoin.
Qed.

Lemma tower_sub r1 r2 n E (e : n.-tuple L) (pw : n.-tuple nat) :
  (forall U x n, r1 U x n -> r2 U x n) ->
    r1.-tower E e pw -> r2.-tower E e pw.
Proof. by move=> sub_r /forallP /= h; apply/forallP=> /= i; apply/sub_r/h. Qed.

Lemma radical_pradical U x p : pradical U x p -> radical U x p.
Proof.
case/pradicalP=> prime_p xpU; apply/radicalP; split=> //.
by case/primeP: prime_p => /ltnW.
Qed.

Lemma radicalext_pradicalext (E F : {subfield L}) :
  pradical.-ext E F -> radical.-ext E F.
Proof.
case=> [[n e pw] Ee FE]; exists (ExtData e pw) => //.
by apply: (tower_sub radical_pradical).
Qed.

Lemma pradicalext_radicalext (E F : {subfield L}) :
  radical.-ext E F -> pradical.-ext E F.
Proof.
case=> [[/= n e pw]]; elim: n e pw E => [|n ih] e pw E Ee FE.
  by rewrite -FE tuple0 /= Fadjoin_nil; apply: rext_refl.
apply: (@rext_trans _ << E; tnth e 0 >>).
  apply: (@pradicalext_radical (tnth pw 0)).
  by move/forallP/(_ ord0): Ee; rewrite take0 Fadjoin_nil.
apply: (ih [tuple of behead e] [tuple of behead pw]) => /=; last first.
  by rewrite -adjoin_cons -drop1 (tnth_nth 0) -drop_nth 1?(drop0, size_tuple).
apply/forallP=> /= i; move/forallP/(_ (rshift 1 i)): Ee => /=.
rewrite !(tnth_nth 0, tnth_nth 0%N) !nth_behead [_ (rshift 1 i)]/=.
by rewrite -adjoin_cons takeD drop1 (take_nth 0) 1?size_tuple // take0.
Qed.

Lemma solvable_by_radical_pradical (E F : {subfield L}) :
  solvable_by pradical E F -> solvable_by radical E F.
Proof. by case=> [R /radicalext_pradicalext ERe FR]; exists R. Qed.

Lemma solvable_by_pradical_radical (E F : {subfield L}) :
  solvable_by radical E F -> solvable_by pradical E F.
Proof. by case=> [R /pradicalext_radicalext ERe FR]; exists R. Qed.

Lemma radicalext_Fadjoin_cyclotomic (E : {subfield L}) (r : L) (n : nat) :
  n.-primitive_root r -> radical.-ext E <<E; r>>%AS.
Proof.
move=> rprim; apply: (@radical_ext_Fadjoin n r E).
  exact: prim_order_gt0 rprim.
by rewrite (prim_expr_order rprim) mem1v.
Qed.

End Properties.
End RadicalExtension.

Arguments tower {F0 L}.
Arguments extension_of {F0 L}.
Arguments radical {F0 L}.

Local Notation "r .-tower" := (tower r)
  (at level 2, format "r .-tower") : ring_scope.
Local Notation "r .-ext" := (extension_of r)
  (at level 2, format "r .-ext") : ring_scope.

(* Following the french wikipedia proof :
https://fr.wikipedia.org/wiki/Th%C3%A9or%C3%A8me_d%27Abel_(alg%C3%A8bre)#D%C3%A9monstration_du_th%C3%A9or%C3%A8me_de_Galois
*)

Section Abel.

(******************************************************************************)
(*                                                                            *)
(* Part 1 : solvable -> radical.-ext                                          *)
(*                                                                            *)
(* With the hypothesis that F has a (order of the galois group)-primitive     *)
(*  root of the unity :                                                       *)
(* Part 1a : if G = Gal(F/E) is abelian, then F has a basis (as an E-vspace)  *)
(*           with only radical elements on E                                  *)
(* Part 1b : recurrence on the solvability chain or the order of the group,   *)
(*           using part1a and radicalext_fixedField                           *)
(*                                                                            *)
(* With the hypothesis that L contains a (order of the galois group) -        *)
(*  primitive root of the unity :                                             *)
(* Part 1c : F is once again a radical extension of E                         *)
(*                                                                            *)
(******************************************************************************)

Section Part1.

Section Part1a.

Import GRing.Theory.

(* - each element of G is diagonalizable *)
(* - the elements of G are simultaneously diagonalizable *)
(* - their eigenvalues are n-th root of the unity because their minimal *)
(*   polynomial divides X^n - 1 *)
(* - let (r1, ..., rn) be their common basis *)
(* - we use the fact :  ri^n is unchanged by any m of G => ri^n is in E *)
(*   - let lambda be the eigenvalue which corresponds to m and ri *)
(*   - then m(ri^n) = (m(ri))^n (m automorphism) *)
(*   - m(ri) = lambda ri (lambda eigenvalue) *)
(*   - lambda^n ri^n = ri^n (lambda is an n-th root of the unity) *)
(*   - ri^n is unchanged by m *)
(*   - then ri^n is in E *)
(* - ri is a radical element on E *)

Lemma abelian_radical_ext (F0 : fieldType) (L : splittingFieldType F0)
    (E F : {subfield L}) (G := 'Gal(F / E)%g) (n := \dim_E F) (r : L) :
      galois E F -> abelian G ->
      r \in E -> (n.-primitive_root r)%R ->
  radical.-ext E F.
Proof.
move=> galois_EF abelian_G r_in_E r_is_nth_root.
have subv_EF := galois_subW galois_EF.
have n_gt0 : (n > 0)%N by rewrite /n -dim_aspaceOver ?adim_gt0.
have asimp := (mem_aspaceOver, subv_adjoin_seq).
suff [/= r_ /andP[r_basis /allP r_F] m_r {abelian_G}] :
     { r_ : n.-tuple L |
       basis_of (aspaceOver E F) (r_ : seq (fieldOver E)) && all (mem F) r_ &
         forall i m, m \in G -> exists2 l, (l \in E) && (l ^+ n == 1)
                                           & m (tnth r_ i) = l * tnth r_ i }.
  pose f i := <<E & take i r_>>%AS.
  have f0E : f 0%N = E by apply/val_inj; rewrite /f/= take0 Fadjoin_nil.
  have Er_eq_F : <<E & r_>>%AS = F :> {vspace _}.
    apply/eqP; rewrite eqEsubv/=; apply/andP; split.
      by apply/Fadjoin_seqP; split.
    apply/subvP => x; rewrite -(mem_aspaceOver subv_EF).
    move=> /(coord_basis r_basis)->; rewrite memv_suml// => i _.
    rewrite fieldOver_scaleE/= rpredM//.
      by rewrite (subvP (subv_adjoin_seq _ _))//; apply: valP.
    have lt_ir : (i < size r_)%N by rewrite size_tuple.
    by rewrite (subvP (seqv_sub_adjoin _ (mem_nth 0 lt_ir)))// memv_line.
  exists (ExtData r_ [tuple of nseq n n]) => //; apply/forallP=> /= i.
  rewrite {2}/tnth nth_nseq ltn_ord; apply/radicalP; split=> //.
  suff: (tnth r_ i) ^+ n \in fixedField G.
    by rewrite (galois_fixedField _)//; apply/(subvP (subv_adjoin_seq _ _)).
  apply/fixedFieldP; first by rewrite rpredX ?[_ \in _]r_F ?mem_nth ?size_tuple.
  move=> g /(m_r i)[l /andP[lE /eqP lX1]].
  by rewrite (tnth_nth 0) rmorphX/= => ->; rewrite exprMn lX1 mul1r.
pose LE := [fieldExtType subvs_of E of fieldOver E].
have [e e_basis] : { e : n.-1.+1.-tuple _ | basis_of (aspaceOver E F) e}.
  rewrite prednK//; have := vbasisP (aspaceOver E F); move: (vbasis _).
  by rewrite dim_aspaceOver// => e; exists e.
have e_free := basis_free e_basis.
have Gminpoly g : g \in G -> mxminpoly (galmx e g) %| 'X ^+ n - 1.
  move=> gG; rewrite mxminpoly_min// rmorphB rmorph1 rmorphX/= horner_mx_X.
  apply: (canLR (addrK _)); rewrite add0r -galmxX//.
  by rewrite [n]galois_dim// expg_cardG// galmx1.
have /sig2W [p p_unit dG] : codiagonalisable [seq galmx e g | g in G].
  apply/codiagonalisableP; split.
    apply/all_commP => _ _ /mapP[g gG ->] /mapP[g' g'G ->].
    rewrite ?mem_enum in gG g'G.
    by rewrite -![_ *m _]galmxM// (centsP abelian_G).
  move=> _/mapP[g gG ->]; rewrite mem_enum in gG *.
  pose l := [seq Subvs r_in_E ^+ i | i <- index_iota 0 n].
  apply/diagonalisableP; exists l.
    rewrite map_inj_in_uniq ?iota_uniq//.
    move=> x y; rewrite !mem_index_iota !leq0n/= => x_n y_n.
    move=> /(congr1 val)/=/eqP; rewrite !rmorphX/=.
    by rewrite (eq_prim_root_expr r_is_nth_root) !modn_small// => /eqP.
  rewrite big_map (@factor_Xn_sub_1 _ _ (Subvs r_in_E)) ?Gminpoly//.
  by rewrite /= -(fmorph_primitive_root [rmorphism of vsval]).
pose r_ := [tuple galvec e (row i p) | i < n.-1.+1].
rewrite -[n]prednK//; exists r_.
  apply/andP; split; last by apply/allP => _ /mapP[/=i _ ->]; rewrite galvec_in.
  rewrite basisEdim; apply/andP; split; last first.
    by rewrite size_tuple dim_aspaceOver// prednK.
  apply/subvP => x /=; rewrite mem_aspaceOver// => xEF.
  have [l ->] : exists l, x = galvec e (l *m p).
    by exists (galrow e x *m invmx p); rewrite mulmxKV ?galrowK.
  rewrite span_def big_map big_enum_cond/= mulmx_sum_row linear_sum/=.
  by  apply: memv_sumr => i _; rewrite linearZ/= [_ \in _]memvZ// memv_line.
move=> i g gG; have /allP /(_ (galmx e g) (map_f _ _))/sim_diagPex := dG.
case=> // [|M pg]; first by rewrite mem_enum.
exists (val (M 0 i)); [apply/andP; split|]; first by rewrite /= subvsP.
  rewrite [X in _ ^+ X]prednK// -subr_eq0.
  have := Gminpoly _ gG; rewrite (simLR _ pg)//.
  move => /dvdpP [q] /(congr1 (val \o horner^~ (M 0 i)))/=.
  rewrite hornerM hornerD hornerN hornerXn hornerC/= rmorphX algid1 => ->.
  rewrite mxminpoly_uconj ?unitmx_inv// mxminpoly_diag/= horner_prod.
  set u := undup _; under eq_bigr do rewrite hornerXsubC.
  suff /eqP-> : \prod_(i0 <- u) (M 0 i - i0) == 0 by rewrite mulr0.
  rewrite prodf_seq_eq0; apply/hasP; exists (M 0 i); rewrite ?subrr ?eqxx//.
  by rewrite mem_undup map_f ?mem_enum.
have /(simP p_unit)/(congr1 (mulmx (@delta_mx _ 1 _ 0 i))) := pg.
rewrite !mulmxA -!rowE row_diag_mx -scalemxAl -rowE => /(congr1 (galvec e)).
by rewrite galvecM// linearZ/= tnth_map tnth_ord_tuple.
Qed.

End Part1a.

Section Part1b.
Variables (F0 : fieldType) (L : splittingFieldType F0).

Lemma solvableWradical_ext (E : {subfield L}) (F : {subfield L}) (r : L) :
  let n := \dim_E F in
  galois E F -> solvable 'Gal(F / E)%g -> r \in E -> n.-primitive_root r ->
  radical.-ext E F.
Proof.
move=> n galEF; have [k] := ubnP n; elim: k => // k IHk in r E F n galEF *.
rewrite ltnS => le_nk; have subEF : (E <= F)%VS by case/andP: galEF.
have n_gt0 : (0 < n)%N by rewrite ltn_divRL ?field_dimS// mul0n adim_gt0.
move=> solEF Er rn; have [n_le1|n_gt1] := leqP n 1%N.
  have /eqP : n = 1%N by case: {+}n n_gt0 n_le1 => [|[]].
  rewrite -eqn_mul ?adim_gt0 ?field_dimS// mul1n eq_sym dimv_leqif_eq//.
  by rewrite val_eqE => /eqP<-; apply: rext_refl.
have /sol_prime_factor_exists[|H Hnormal] := solEF.
  by rewrite -cardG_gt1 -galois_dim.
have [<-|H_neq] := eqVneq H ('Gal(F / E))%G; first by rewrite indexgg.
have galEH := normal_fixedField_galois galEF Hnormal.
have subEH : (E <= fixedField H)%VS by case/andP: galEH.
rewrite -dim_fixed_galois ?normal_sub// galois_dim//=.
pose d := \dim_E (fixedField H); pose p := \dim_(fixedField H) F.
have p_gt0 : (p > 0)%N by rewrite divn_gt0 ?adim_gt0 ?dimvS ?fixedField_bound.
have n_eq : n = (p * d)%N by rewrite /p /d -dim_fixedField dim_fixed_galois;
                             rewrite ?Lagrange ?normal_sub -?galois_dim.
have Erm : r ^+ (n %/ d) \in E by rewrite rpredX.
move=> /prime_cyclic/cyclic_abelian/abelian_radical_ext/(_ Erm)-/(_ galEH)/=.
rewrite dvdn_prim_root// => [/(_ isT)|]; last by rewrite n_eq dvdn_mull.
move=> /rext_trans; apply.
apply: (IHk (r ^+ (n %/ p))) => /=.
- exact: fixedField_galois.
- rewrite (leq_trans _ le_nk)// -dim_fixedField /n galois_dim// proper_card//.
  by rewrite properEneq H_neq normal_sub.
- by rewrite gal_fixedField (solvableS (normal_sub Hnormal)).
- by rewrite rpredX//; apply: subvP Er.
- by rewrite dvdn_prim_root// n_eq dvdn_mulr.
Qed.

End Part1b.

Section Part1c.

(* common context *)
Variables (F0 : fieldType) (L : splittingFieldType F0).
Variables (E F : {subfield L}).
Hypothesis galois_EF : galois E F.
Local Notation G := ('Gal(F / E)%g).
Local Notation n := (\dim_E F).
Variable (r : L).
Hypothesis r_root : (n.-primitive_root r)%R.
Hypothesis solvable_G : solvable G.

Let subEF : (E <= F)%VS := galois_subW galois_EF.

Lemma galois_solvable_by_radical : solvable_by radical E F.
Proof.
pose G : {group gal_of F} := 'Gal(F / F :&: <<E; r>>%AS)%G.
have EEr := subv_adjoin E r.
rewrite /solvable_by; exists (F * <<E; r>>)%AS; last first.
  by rewrite field_subvMr; split.
apply: rext_trans (radicalext_Fadjoin_cyclotomic _ r_root) _.
have galErFEr: galois <<E; r>>%AS (F * <<E; r>>)%AS.
  by rewrite (@galois_prodvr _ _ E).
pose r' := r ^+ (n %/ #|G|).
have r'prim : #|G|.-primitive_root r'.
  by apply: dvdn_prim_root; rewrite // galois_dim ?cardSg ?galS ?subv_cap ?subEF.
have r'Er : r' \in <<E; r>>%VS by rewrite rpredX ?memv_adjoin.
apply: solvableWradical_ext r'Er _ => //=.
  rewrite (isog_sol (galois_isog galois_EF _))//.
  by apply: solvableS solvable_G; apply: galS; rewrite subv_cap subEF.
by rewrite galois_dim// (card_isog (galois_isog galois_EF _)).
Qed.

End Part1c.

(* Main lemma of part 1 *)
Lemma ext_solvable_by_radical (F0 : fieldType) (L : splittingFieldType F0)
    (r : L) (E F : {subfield L}) :
    (\dim_E (minGalois E F)).-primitive_root r ->
  solvable_ext E F -> solvable_by radical E F.
Proof.
move=> rprim /andP[sepEF].
move=> /(galois_solvable_by_radical (minGalois_galois sepEF)).
move=> /(_ r rprim) [M EM EFM]; exists M => //.
by rewrite (subv_trans _ EFM) ?sub_minGalois.
Qed.

End Part1.

(******************************************************************************)
(*                                                                            *)
(* Part 2 : solvable_by_radicals -> solvable                                  *)
(*                                                                            *)
(******************************************************************************)

Lemma radical_solvable_ext (F0 : fieldType) (L : splittingFieldType F0)
    (E F : {subfield L}) : [char L] =i pred0 -> (E <= F)%VS ->
  solvable_by radical E F -> solvable_ext E F.
Proof.
move: L E F => L' E' F' charL' EF'.
have charF0 : [char F0] =i pred0 by move=> i; rewrite -charL' char_lalg.
move=> [_ /pradicalext_radicalext[[/= n e' pw] /towerP epwP' <- FK']].
pose d := (\prod_(i < n) tnth pw i)%N.
have d_gt0 : (0 < d)%N.
  by rewrite prodn_gt0// => i; have /pradicalP[/prime_gt0]:= epwP' i.
have dF0N0: d%:R != 0 :> F0.
  rewrite natf_neq0; apply/pnatP => // p p_prime dvdpd; rewrite /negn/= inE/=.
  by rewrite -(char_lalg L') charL'.
(* classically grabbing a root of the unity and changing fields from L to L' *)
apply: (@classic_cycloSplitting _ L' _ dF0N0) => -[L [r [iota r_full r_root]]].
rewrite -(solvable_ext_img iota).
set E := (iota @: E')%VS.
set F := (iota @: F')%VS.
pose e := [tuple of map iota e'].
pose K := <<E & e>>%VS.
have FK : (F <= <<E & e>>)%VS by rewrite -aimg_adjoin_seq limgS.
have EF : (E <= F)%VS by rewrite limgS.
have EK : (E <= K)%VS by apply: subv_trans FK.
have charL : [char L] =i pred0 by move=> x; rewrite char_lalg.
have epwP : forall i : 'I_n, pradical <<E & take i e>> (tnth e i) (tnth pw i).
  move=> i; have /pradicalP[pwi_prime e'i_rad] := epwP' i.
  apply/pradicalP; split; rewrite // -map_take -aimg_adjoin_seq.
  by rewrite tnth_map -rmorphX/= memv_img.
suff /solvable_extP [M /and3P[KrsubM EM solEM]] : solvable_ext E <<K; r>>%AS.
  apply/solvable_extP; exists M; rewrite EM solEM (subv_trans _ KrsubM)//=.
  by rewrite (subv_trans _ (subv_adjoin _ _)).
pose k := n; have -> : <<K ; r>>%AS = <<E & r :: take k e>>%AS.
  rewrite take_oversize ?size_tuple//.
  apply/val_inj; rewrite /= -adjoin_rcons.
  by rewrite (@eq_adjoin _ _ _ (rcons _ _) (r :: e))// => x; rewrite mem_rcons.
elim: k => /= [|k IHsol]; rewrite ?take0 ?adjoin_seq1.
  apply/solvable_extP; exists <<E & [:: r] >>%AS.
  rewrite /= adjoin_seq1 subvv/= (galois_Fadjoin_cyclotomic _ r_root).
  by rewrite (solvable_Fadjoin_cyclotomic _ r_root).
have [ltnk|lenk] := ltnP k n; last first.
  by rewrite !take_oversize ?size_tuple// leqW in IHsol *.
rewrite (take_nth r) ?size_tuple// -rcons_cons adjoin_rcons.
pose ko := Ordinal ltnk; have /pradicalP[pwk_prime ekP] := epwP ko.
have [ekE|ekNE] := boolP (nth r e k \in <<E & r :: take k e>>%VS).
  by rewrite (Fadjoin_idP _).
have prim : (tnth pw ko).-primitive_root (r ^+ (d %/ tnth pw ko)).
  by rewrite dvdn_prim_root// /d (bigD1 ko)//= dvdn_mulr.
apply: solvable_ext_trans IHsol _; first by rewrite subv_adjoin_seq subv_adjoin.
rewrite (solvable_ext_Fadjoin_prime prim _ _ _ pwk_prime)//.
  rewrite -[k]/(val ko) -tnth_nth; apply: subvP ekP.
  by apply: adjoin_seqSr => x xe; rewrite in_cons xe orbT.
by rewrite /= adjoin_cons rpredX// (subvP (subv_adjoin_seq _ _))// memv_adjoin.
Qed.

(******************************************************************************)
(*                                                                            *)
(* Abel/Galois Theorem                                                        *)
(*                                                                            *)
(******************************************************************************)

(** Ok **)
Lemma AbelGalois  (F0 : fieldType) (L : splittingFieldType F0) (r : L)
  (E F : {subfield L}) : (E <= F)%VS -> [char L] =i pred0 ->
  (\dim_E (minGalois E F)).-primitive_root r ->
  (solvable_by radical E F) <-> (solvable_ext E F).
Proof.
move=> EF charL rprim; split; first exact: radical_solvable_ext.
exact: (ext_solvable_by_radical rprim).
Qed.

End Abel.

Definition solvable_by_radical_poly (F : fieldType) (p : {poly F}) :=
  forall (L : splittingFieldType F) (rs : seq L),
    p ^^ in_alg L %= \prod_(x <- rs) ('X - x%:P) ->
    forall r : L, (\dim (minGalois 1%VS <<1 & rs>>%VS)).-primitive_root r ->
    solvable_by radical 1%AS  <<1 & rs>>%AS.

Definition solvable_ext_poly (F : fieldType) (p : {poly F}) :=
  forall (L : splittingFieldType F) (rs : seq L),
    p ^^ in_alg L %= \prod_(x <- rs) ('X - x%:P) ->
    solvable_ext 1%VS <<1 & rs>>%VS.

Lemma AbelGaloisPoly (F : fieldType) (p : {poly F}) : [char F] =i pred0 ->
  (solvable_ext_poly p) <-> (solvable_by_radical_poly p).
Proof.
move=> charF; split=> + L rs pE => [/(_ L rs pE) + r r_prim|solrs]/=.
  have charL : [char L] =i pred0 by move=> i; rewrite char_lalg.
  move=> /AbelGalois-/(_ r (sub1v _) charL)/=.
  by rewrite dimv1 divn1 => /(_ r_prim).
have charL : [char L] =i pred0 by move=> i; rewrite char_lalg.
have seprs: separable 1 <<1 & rs>> by apply/char0_separable.
pose n := \dim (minGalois 1 <<1 & rs>>).
have nFN0 : n%:R != 0 :> F by have /charf0P-> := charF; rewrite -lt0n adim_gt0.
apply: (@classic_cycloSplitting _ L _ nFN0) => - [L' [r [iota rL' r_prim]]].
rewrite -(solvable_ext_img iota).
have charL' : [char L'] =i pred0 by move=> i; rewrite char_lalg.
apply/(@AbelGalois _ _ r) => //.
- by rewrite limgS// sub1v.
- by rewrite -aimg_minGalois //= aimg1 dimv1 divn1 dim_aimg.
have /= := solrs L' (map iota rs) _ r.
rewrite -(aimg1 iota) -!aimg_adjoin_seq -aimg_minGalois// dim_aimg.
apply => //; have := pE; rewrite -(eqp_map [rmorphism of iota]).
by rewrite -map_poly_comp/= (eq_map_poly (rmorph_alg _)) map_prod_XsubC.
Qed.

Lemma solvable_ext_polyP (F : fieldType) (p : {poly F}) : p != 0 ->
    [char F] =i pred0 ->
  solvable_ext_poly p <->
  classically (exists (L : splittingFieldType F) (rs : seq L),
                p ^^ in_alg L %= \prod_(x <- rs) ('X - x%:P) /\
                solvable_ext 1 <<1 & rs>>).
Proof.
move=> p_neq0 charF; split => sol_p.
have FoE (v : F^o) : v = in_alg F^o v by rewrite /= /(_%:A)/= mulr1.
apply: classic_bind (@classic_fieldExtFor _ _ (p : {poly F^o}) p_neq0).
  move=> [L [rs [iota rsf p_eq]]]; apply/classicW.
  have iotaF : iota =1 in_alg L by move=> v; rewrite [v in LHS]FoE rmorph_alg.
  have splitL : SplittingField.axiom L.
    exists (p ^^ iota).
      by apply/polyOver1P; exists p; apply: eq_map_poly.
    exists rs => //; suff <- : limg iota = 1%VS by [].
    apply/eqP; rewrite eqEsubv sub1v andbT; apply/subvP => v.
    by move=> /memv_imgP[u _ ->]; rewrite iotaF/= rpredZ// rpred1.
  pose S := SplittingFieldType F L splitL.
  exists S, rs; split => //=; first by rewrite -(eq_map_poly iotaF).
  by apply: (sol_p S rs); rewrite -(eq_map_poly iotaF).
move=> L rs prs; apply: sol_p => -[M [rs' [prs']]].
have charL : [char L] =i pred0 by move=> n; rewrite char_lalg charF.
have charM : [char M] =i pred0 by move=> n; rewrite char_lalg charF.
rewrite !char0_solvable_extE//= !minGalois_id//; last 2 first.
- apply/char0_galois; rewrite ?sub1v//.
  apply/splitting_normalField; rewrite ?sub1v//.
  exists (p ^^ in_alg L); first by apply/polyOver1P; exists p.
  by exists rs => //.
- apply/char0_galois; rewrite ?sub1v//.
  apply/splitting_normalField; rewrite ?sub1v//.
  exists (p ^^ in_alg M); first by apply/polyOver1P; exists p.
  by exists rs' => //.
pose K := [fieldExtType F of subvs_of <<1 & rs>>%VS].
pose rsK := map (vsproj <<1 & rs>>%VS) rs.
have pKrs : p ^^ in_alg K %= \prod_(x <- rsK) ('X - x%:P).
  rewrite -(eqp_map [rmorphism of vsval])/= map_prod_XsubC/= -map_poly_comp/=.
  rewrite -map_comp (@eq_map_poly _ _ _ (in_alg L)); last first.
    by move=> v; rewrite /= algid1.
  have /eq_in_map-> : {in rs, cancel (vsproj <<1 & rs>>%VS) vsval}.
    by move=> x xrs; rewrite vsprojK// seqv_sub_adjoin.
  by rewrite big_map.
have splitK : splittingFieldFor 1 (p ^^ in_alg K) fullv.
  exists rsK => //; apply/eqP; rewrite eqEsubv subvf/=.
  rewrite -(@limg_ker0 _ _ _ (linfun vsval)) ?AHom_lker0//.
  rewrite aimg_adjoin_seq/= aimg1 -map_comp/=.
  have /eq_in_map-> : {in rs, cancel (vsproj <<1 & rs>>%VS) (linfun vsval)}.
    by move=> x xrs; rewrite lfunE/= vsprojK// seqv_sub_adjoin.
  rewrite map_id; apply/subvP => _/memv_imgP[v _ ->].
  by rewrite lfunE subvsP.
have sfK : SplittingField.axiom K.
  by exists (p ^^ in_alg K) => //; apply/polyOver1P; exists p.
pose S := SplittingFieldType F K sfK.
have splitS : splittingFieldFor 1 (p ^^ in_alg S) fullv by [].
have splitM : splittingFieldFor 1 (p ^^ in_alg M) <<1 & rs'>> by exists rs'.
have splitL : splittingFieldFor 1 (p ^^ in_alg L) <<1 & rs>> by exists rs.
have [f imgf] := splitting_ahom splitS splitM.
have [g imgg] := splitting_ahom splitS splitL.
rewrite -imgf -(aimg1 f)/= -img_map_gal injm_sol ?map_gal_inj ?subsetT//.
by rewrite -imgg -(aimg1 g)/= -img_map_gal injm_sol ?map_gal_inj ?subsetT//.
Qed.

Lemma solvable_by_radical_polyP (F : fieldType) (p : {poly F}) : p != 0 ->
    [char F] =i pred0 ->
  solvable_by_radical_poly p <->
  classically (exists (L : splittingFieldType F) (rs : seq L),
                p ^^ in_alg L %= \prod_(x <- rs) ('X - x%:P) /\
                solvable_by radical 1 <<1 & rs>>).
Proof.
move=> p_neq0 charF0; split => sol_p; last first.
  apply/AbelGaloisPoly => //; apply/solvable_ext_polyP => //.
  apply: classic_bind sol_p => -[L [rs [prs sol_p]]]; apply/classicW.
  exists L, rs; split => //.
  apply: radical_solvable_ext; rewrite ?sub1v// => v.
  by rewrite char_lalg charF0.
have FoE (v : F^o) : v = in_alg F^o v by rewrite /= /(_%:A)/= mulr1.
apply: classic_bind (@classic_fieldExtFor _ _ (p : {poly F^o}) p_neq0).
move=> [L [rs [f rsf p_eq]]].
have fF : f =1 in_alg L by move=> v; rewrite [v in LHS]FoE rmorph_alg.
have splitL : SplittingField.axiom L.
  exists (p ^^ f); first by apply/polyOver1P; exists p; apply: eq_map_poly.
  exists rs => //; suff <- : limg f = 1%VS by [].
  apply/eqP; rewrite eqEsubv sub1v andbT; apply/subvP => v.
  by move=> /memv_imgP[u _ ->]; rewrite fF/= rpredZ// rpred1.
pose S := SplittingFieldType F L splitL.
pose d := \dim (minGalois 1 <<1 & (rs : seq S)>>).
have /classic_cycloSplitting-/(_ S) : d%:R != 0 :> F.
  by have /charf0P-> := charF0; rewrite -lt0n adim_gt0.
apply/classic_bind => -[C [r [g rg r_prim]]]; apply/classicW.
have gf : g \o f =1 in_alg C by move=> v /=; rewrite fF rmorph_alg.
have pgrs : p ^^ in_alg C %= \prod_(x <- [seq g i | i <- rs]) ('X - x%:P).
  by rewrite -(eq_map_poly gf) map_poly_comp/= -map_prod_XsubC eqp_map//.
have charL : [char L] =i pred0 by move=> i; rewrite char_lalg.
exists C, (map g rs); split => //=.
apply: (sol_p C (map g rs) _ r) => //.
rewrite -(aimg1 g) -aimg_adjoin_seq.
by rewrite -aimg_minGalois ?char0_separable ?dim_aimg.
Qed.

Import GRing.Theory Order.Theory Num.Theory.

Lemma solvable_poly_rat (p : {poly rat}) : p != 0 ->
  solvable_by_radical_poly p ->
  {L : splittingFieldType rat & {iota : {rmorphism L -> algC} & { rs : seq L |
   p ^^ in_alg L %= \prod_(x <- rs) ('X - x%:P) /\
   solvable_by radical 1 <<1 & rs>>}}}.
Proof.
move=> p_neq0 p_sol.
have [/= rsalg pE] := closed_field_poly_normal (p ^^ (ratr : _ -> algC)).
have {}pE : p ^^ ratr %= \prod_(z <- rsalg) ('X - z%:P).
  rewrite pE (eqp_trans (eqp_scale _ _)) ?eqpxx//.
  by rewrite lead_coef_map//= fmorph_eq0 lead_coef_eq0.
have [L [iota [rs iota_rs rsf]]] := num_field_exists rsalg.
have prs : p ^^ in_alg L %= \prod_(z <- rs) ('X - z%:P).
  rewrite -(eqp_map iota) map_prod_XsubC iota_rs -map_poly_comp.
  by rewrite (eq_map_poly (fmorph_eq_rat _)).
have splitL : SplittingField.axiom L.
  by exists (p ^^ in_alg L); [by apply/polyOver1P; exists p | exists rs].
pose S := SplittingFieldType rat L splitL.
pose d := \dim (minGalois 1 <<1 & (rs : seq S)>>).
have d_gt0 : (d > 0)%N by rewrite adim_gt0.
have [ralg ralg_prim] := C_prim_root_exists d_gt0.
have [L' [iota' [[]//= r rs' [iotar iota_rs' rrsf]]]] :=
  num_field_exists (ralg :: rsalg).
have prs' : p ^^ in_alg L' %= \prod_(z <- rs') ('X - z%:P).
  rewrite -(eqp_map iota') map_prod_XsubC iota_rs' -map_poly_comp.
  by rewrite (eq_map_poly (fmorph_eq_rat _)).
have r_prim : d.-primitive_root r.
  by move: ralg_prim; rewrite -iotar fmorph_primitive_root.
have splitL' : SplittingField.axiom L'.
  exists (cyclotomic r d * p ^^ in_alg L').
    by rewrite rpredM ?cyclotomic_over//; apply/polyOver1P; exists p.
  have [us cycloE usr] := splitting_Fadjoin_cyclotomic 1%AS r_prim.
  exists (us ++ rs'); last by rewrite adjoin_cat usr -adjoin_cons.
  by rewrite big_cat/= (eqp_trans (eqp_mulr _ cycloE))// eqp_mull//.
pose S' := SplittingFieldType rat L' splitL'.
have splitS : splittingFieldFor 1 (p ^^ in_alg S) fullv by exists rs.
have splitS' : splittingFieldFor 1 (p ^^ in_alg S') <<1 & rs'>> by exists rs'.
have [f /= imgf] := splitting_ahom splitS splitS'.
exists S', iota', rs'; split => //; apply: (p_sol S' rs' prs' r).
have charS : [char S] =i pred0 by move=> i; rewrite char_lalg char_num.
by rewrite -imgf -(aimg1 f) -aimg_minGalois ?char0_separable// dim_aimg/= -rsf.
Qed.

Open Scope ring_scope.

Section Formula.
Definition omega_ n := projT1 (@C_prim_root_exists n.-1.+1 isT).

Lemma omega_prim n : (n > 0)%N -> n.-primitive_root (omega_ n).
Proof. by case: n => [|n]// _; rewrite /omega_; case: C_prim_root_exists. Qed.

Inductive const := Zero | One | URoot of nat.
Inductive binOp := Add | Mul.
Inductive unOp := Opp | Inv | Exp of nat | Root of nat.
Inductive algformula (F : Type) : Type :=
| Base of F
| Const of const
| UnOp of unOp & algformula F
| BinOp of binOp & algformula F & algformula F.
Arguments Const {F}.

Definition encode_const (c : const) : nat :=
   match c with Zero => 0 | One => 1 | URoot n => n.+2 end.
Definition decode_const (n : nat) : const :=
   match n with 0 => Zero | 1 => One | n.+2 => URoot n end.
Lemma code_constK : cancel encode_const decode_const.
Proof. by case. Qed.
Definition const_eqMixin := CanEqMixin code_constK.
Canonical const_eqType := EqType const const_eqMixin.
Definition const_choiceMixin := CanChoiceMixin code_constK.
Canonical const_choiceType := ChoiceType const const_choiceMixin.
Definition const_countMixin := CanCountMixin code_constK.
Canonical const_countType := CountType const const_countMixin.

Definition encode_binOp (c : binOp) : bool :=
   match c with Add => false | Mul => true end.
Definition decode_binOp (b : bool) : binOp :=
   match b with false => Add | _ => Mul end.
Lemma code_binOpK : cancel encode_binOp decode_binOp.
Proof. by case. Qed.
Definition binOp_eqMixin := CanEqMixin code_binOpK.
Canonical binOp_eqType := EqType binOp binOp_eqMixin.
Definition binOp_choiceMixin := CanChoiceMixin code_binOpK.
Canonical binOp_choiceType := ChoiceType binOp binOp_choiceMixin.
Definition binOp_countMixin := CanCountMixin code_binOpK.
Canonical binOp_countType := CountType binOp binOp_countMixin.

Definition encode_unOp (c : unOp) : nat + nat :=
   match c with Opp => inl _ 0%N | Inv => inl _ 1%N
           | Exp n => inl _ n.+2 | Root n => inr _ n end.
Definition decode_unOp (n : nat + nat) : unOp :=
   match n with inl 0 => Opp | inl 1 => Inv
           | inl n.+2 => Exp n | inr n => Root n end.
Lemma code_unOpK : cancel encode_unOp decode_unOp.
Proof. by case. Qed.
Definition unOp_eqMixin := CanEqMixin code_unOpK.
Canonical unOp_eqType := EqType unOp unOp_eqMixin.
Definition unOp_choiceMixin := CanChoiceMixin code_unOpK.
Canonical unOp_choiceType := ChoiceType unOp unOp_choiceMixin.
Definition unOp_countMixin := CanCountMixin code_unOpK.
Canonical unOp_countType := CountType unOp unOp_countMixin.

Fixpoint encode_algf F (f : algformula F) : GenTree.tree (F + const) :=
  let T_ isbin := if isbin then binOp else unOp in
  match f with
  | Base x => GenTree.Leaf (inl x)
  | Const c => GenTree.Leaf (inr c)
  | UnOp u f1 => GenTree.Node (pickle (inl u : unOp + binOp))
                              [:: encode_algf f1]
  | BinOp b f1 f2 => GenTree.Node (pickle (inr b : unOp + binOp))
                                  [:: encode_algf f1; encode_algf f2]
  end.
Fixpoint decode_algf F (t : GenTree.tree (F + const)) : algformula F :=
  match t with
  | GenTree.Leaf (inl x) => Base x
  | GenTree.Leaf (inr c) => Const c
  | GenTree.Node n fs =>
    match locked (unpickle n), fs with
    | Some (inl u), f1 :: _ => UnOp u (decode_algf f1)
    | Some (inr b), f1 :: f2 :: _ => BinOp b (decode_algf f1) (decode_algf f2)
    | _, _ => Const Zero
    end
  end.
Lemma code_algfK F : cancel (@encode_algf F) (@decode_algf F).
Proof.
by elim => // [u f IHf|b f IHf f' IHf']/=; rewrite pickleK -lock ?IHf ?IHf'.
Qed.
Definition algf_eqMixin (F : eqType) := CanEqMixin (@code_algfK F).
Canonical algf_eqType (F : eqType) := EqType (algformula F) (@algf_eqMixin F).
Definition algf_choiceMixin (F : choiceType) := CanChoiceMixin (@code_algfK F).
Canonical algf_choiceType (F : choiceType) :=
  ChoiceType (algformula F) (@algf_choiceMixin F).
Definition algf_countMixin (F : countType) := CanCountMixin (@code_algfK F).
Canonical algf_countType (F : countType) :=
  CountType (algformula F) (@algf_countMixin F).

Declare Scope algf_scope.
Delimit Scope algf_scope with algf.
Bind Scope algf_scope with algformula.
Local Notation "0" := (Const Zero) : algf_scope.
Local Notation "1" := (Const One) : algf_scope.
Local Notation "- x" := (UnOp Opp x) : algf_scope.
Local Notation "- 1" := (- (1)) : algf_scope.
Local Infix "+" := (BinOp Add) : algf_scope.
Local Notation "x ^-1" := (UnOp Inv x) : algf_scope.
Local Infix "*" := (BinOp Mul) : algf_scope.
Local Notation "x ^+ n" := (UnOp (Exp n) x) : algf_scope.
Local Notation "n '.-root'" := (UnOp (Root n)) : algf_scope.
Local Notation Omega_ j := (Const (URoot j)).

Section eval.
Variables (F : fieldType) (iota : F -> algC).
Fixpoint alg_eval (f : algformula F) : algC :=
  match f with
  | Base x => iota x
  | 0%algf => 0
  | 1%algf  => 1
  | (f1 + f2)%algf => alg_eval f1 + alg_eval f2
  | (- f1)%algf => - alg_eval f1
  | (f1 * f2)%algf => alg_eval f1 * alg_eval f2
  | (f1 ^-1)%algf => (alg_eval f1)^-1
  | (f1 ^+ n)%algf => (alg_eval f1) ^+ n
  | (n.-root f1)%algf => nthroot n.+1 (alg_eval f1)
  | Omega_ j => omega_ j.+1
  end.

Fixpoint subeval (f : algformula F) : seq algC :=
  alg_eval f :: match f with
  | UnOp _ f1 => subeval f1
  | BinOp _ f1 f2 => subeval f1 ++ subeval f2
  | _ => [::]
  end.

Lemma subevalE f : subeval f = alg_eval f :: behead (subeval f).
Proof. by case: f => *. Qed.

End eval.

Lemma solvable_formula (p : {poly rat}) : p != 0 ->
  solvable_by_radical_poly p <->
  {in root (p ^^ ratr), forall x,
     exists f : algformula rat, alg_eval ratr f = x}.
Proof.
have Cchar := Cchar => p_neq0; split.
  move=> /solvable_poly_rat[]// L [iota [rs [prs [E rE KE]]]] x.
  have pirs : p ^^ ratr %= \prod_(x <- map iota rs) ('X - x%:P).
    have := prs; rewrite -(eqp_map iota) map_prod_XsubC => /eqp_rtrans<-.
    by rewrite -map_poly_comp (eq_map_poly (fmorph_eq_rat _)) eqpxx.
  rewrite -topredE/= (eqp_root pirs) root_prod_XsubC => /mapP[{}r rrs ->].
  suff [f <- /=]: exists f : algformula (subvs_of (1%VS : {vspace L})),
      alg_eval (iota \o vsval) f = iota r.
    elim: f => //= [[/= _/vlineP[s ->]]|cst|op|op].
    - exists (Base s) => /=.
      by rewrite [RHS](fmorph_eq_rat [rmorphism of iota \o in_alg L]).
    - by exists (Const cst).
    - by move=> _ [f1 <-]; exists (UnOp op f1).
    - by move=> _ [f1 <-] _ [f2 <-]; exists (BinOp op f1 f2).
  have: r \in E by rewrite (subvP KE)// seqv_sub_adjoin.
  case: rE => -[/= n e pw] epw <-.
  rewrite -[1%VS]/(1%AS : {vspace _}) in epw *.
  elim: n 1%AS => [|n IHn] k /= in e pw epw *.
    by rewrite tuple0 Fadjoin_nil => rk; exists (Base (Subvs rk)).
  case: (tupleP e) (tupleP pw) epw => [u e'] [i pw']/= epw.
  rewrite adjoin_cons => /IHn-/(_ pw')[].
    apply/towerP => j /=.
    have /towerP/(_ (lift ord0 j))/= := epw.
    by rewrite !tnthS/= adjoin_cons.
  move=> f <-; elim: f => //= [s|cst|op|op]; last 3 first.
  - by exists (Const cst).
  - by move=> _ [f1 <-]; exists (UnOp op f1).
  - by move=> _ [f1 <-] _ [f2 <-]; exists (BinOp op f1 f2).
  have /Fadjoin_polyP[q qk ->] := subvsP s.
  have /towerP/(_ ord0) := epw; rewrite !tnth0/= Fadjoin_nil.
  move=> /radicalP[]; case: i => // i in epw * => _ uik.
  pose v := i.+1.-root (iota (u ^+ i.+1)).
  have : ('X ^+ i.+1 - (v ^+ i.+1)%:P).[iota u] == 0.
    by rewrite !hornerE hornerXn rootCK// rmorphX subrr.
  have /Xn_sub_xnE->// := omega_prim (isT : 0 < i.+1)%N.
  rewrite horner_prod prodf_seq_eq0/= => /hasP[/= l _].
  rewrite hornerXsubC subr_eq0 => /eqP u_eq.
  pose fu := (i.-root (Base (Subvs uik)) * (Omega_ i ^+ l))%algf.
  rewrite -horner_map; have -> : iota u = alg_eval (iota \o vsval) fu by [].
  move: fu => fu; elim/poly_ind: q qk => //= [|q c IHq] qXDck.
    by exists 0%algf; rewrite rmorph0 horner0.
  have ck : c \in k.
    by have /polyOverP/(_ 0%N) := qXDck; rewrite coefD coefMX coefC/= add0r.
  have qk : q \is a polyOver k.
    apply/polyOverP => j; have /polyOverP/(_ j.+1) := qXDck.
    by rewrite coefD coefMX coefC/= addr0.
  case: IHq => // fq fq_eq.
  exists (fq * fu + Base (Subvs ck))%algf => /=.
  by rewrite rmorphD rmorphM/= map_polyX map_polyC !hornerE fq_eq.
move=> mkalg; apply/solvable_by_radical_polyP => //=; first exact: char_num.
have [/= rsalg pE] := closed_field_poly_normal (p ^^ (ratr : _ -> algC)).
have {}pE : p ^^ ratr %= \prod_(z <- rsalg) ('X - z%:P).
  rewrite pE (eqp_trans (eqp_scale _ _)) ?eqpxx//.
  by rewrite lead_coef_map//= fmorph_eq0 lead_coef_eq0.
have [fs fsE] : exists fs, map (alg_eval ratr) fs = rsalg.
  have /(_ _ _)/sig_eqW-/(all_sig_cond (Base 0)) [h hE] :
      forall x : algC, x \in rsalg -> exists f, alg_eval ratr f = x.
    by move=> *; apply: mkalg; rewrite -topredE/= (eqp_root pE) root_prod_XsubC.
  by exists (map h rsalg); rewrite -map_comp map_id_in//.
pose algs := flatten (map (subeval ratr) fs).
pose mp := \prod_(x <- algs) projT1 (minCpolyP x).
have mp_monic : mp \is monic.
  by rewrite monic_prod => // i _; case: minCpolyP => /= ? [].
have mpratr : mp ^^ ratr = \prod_(x <- algs) minCpoly x.
  rewrite rmorph_prod/=; apply: eq_bigr => x _.
  by case: minCpolyP => //= ? [].
have [rsmpalg mpE] := closed_field_poly_normal (mp ^^ ratr : {poly algC}).
have mp_neq0 : mp != 0.
  rewrite prodf_seq_eq0; apply/hasPn => /= x xalgs.
  by case: minCpolyP => //= ? [_ /monic_neq0->].
have {}mpE : mp ^^ ratr = \prod_(z <- rsmpalg) ('X - z%:P).
  by rewrite mpE lead_coef_map/= (eqP mp_monic) rmorph1 scale1r.
have [L [iota [rsmp iota_rs rsf]]] := num_field_exists rsmpalg.
have charL : [char L] =i pred0 by move=> x; rewrite char_lalg char_num.
have mprs : mp ^^ in_alg L %= \prod_(z <- rsmp) ('X - z%:P).
  rewrite -(eqp_map iota) map_prod_XsubC iota_rs -map_poly_comp -mpE.
  by rewrite -char0_ratrE// (eq_map_poly (fmorph_eq_rat _)) eqpxx.
have splitL : SplittingField.axiom L.
  by exists (mp ^^ in_alg L); [apply/polyOver1P; exists mp | exists rsmp].
pose S := SplittingFieldType rat L splitL.
have algsW: {subset rsalg <= algs}.
  move=> x; rewrite -fsE => /mapP[{x}f ffs ->].
  apply/flattenP; exists (subeval ratr f); rewrite ?map_f//.
  by rewrite subevalE mem_head.
have rsmpW: {subset algs <= rsmpalg}.
  move=> x xalgs; rewrite -root_prod_XsubC -mpE mpratr.
  by rewrite (big_rem _ xalgs)/= rootM root_minCpoly.
have := rsmpW; rewrite -iota_rs => /(subset_mapP 0)[als _ /esym alsE].
have := algsW; rewrite -alsE => /(subset_mapP 0)[rs _ /esym rsE].
have prs : p ^^ in_alg S %= \prod_(x <- rs) ('X - x%:P).
  rewrite -(eqp_map iota) -map_poly_comp (eq_map_poly (fmorph_eq_rat _)).
  by rewrite map_prod_XsubC rsE.
apply/classicW; exists S, rs; split => //.
exists <<1 & als>>%AS; last first.
  rewrite adjoin_seqSr// => x /(map_f iota); rewrite rsE => /algsW.
  by rewrite -[X in _ \in X]alsE (mem_map (fmorph_inj _)).
rewrite {p p_neq0 mkalg pE prs rsmp iota_rs mprs rsf rs rsE mp
        mp_monic mpratr rsmpalg mp_neq0 mpE algsW rsmpW charL}/=.
suff: forall (L : splittingFieldType rat) (iota : {rmorphism L -> algC}) als,
        map iota als = algs -> radical.-ext 1%VS <<1 & als>>%VS.
  by move=> /(_ S iota als alsE).
move=> {}L {}iota {splitL S} {}als {}alsE; rewrite {}/algs in alsE.
elim: fs => [|f fs IHfs]//= in rsalg fsE als alsE *.
  case: als => []// in alsE *.
  by rewrite Fadjoin_nil; apply: rext_refl.
move: rsalg fsE => [|r rsalg]// [fr fsE].
pose n := size (subeval ratr f); rewrite -[als](cat_take_drop n).
have /(congr1 (take n)) := alsE; rewrite take_size_cat//.
rewrite -map_take; move: (take _ _) => als1 als1E.
have /(congr1 (drop n)) := alsE; rewrite drop_size_cat//.
rewrite -map_drop; move: (drop _ _) => als2 als2E.
have /rext_trans := IHfs _ fsE _ als2E; apply.
have -> : <<1 & als1 ++ als2>>%AS = <<<<1 & als2>>%AS & als1>>%AS.
  apply/val_inj; rewrite /= -adjoin_cat; apply/eq_adjoin => x.
  by rewrite !mem_cat orbC.
move: <<1 & als2>>%AS => /= k {als2 als2E n fs fsE IHfs rsalg als alsE}.
elim: f => //= [x|c|u f1 IHf1|b f1 IHf1 f2 IHf2] in k {r fr} als1 als1E *.
- case: als1 als1E => [|y []]//= [yx]/=.
  rewrite adjoin_seq1 (Fadjoin_idP _); first exact: rext_refl.
  suff: y \in 1%VS by apply/subvP; rewrite sub1v.
  apply/vlineP; exists x; apply: (fmorph_inj iota); rewrite yx.
  by rewrite [RHS](fmorph_eq_rat [rmorphism of iota \o in_alg _]).
- case: als1 als1E => [|y []]//= []/=; rewrite adjoin_seq1.
  case: c => [/eqP|/eqP|n yomega].
  + rewrite fmorph_eq0 => /eqP->; rewrite (Fadjoin_idP _) ?rpred0//.
    exact: rext_refl.
  + rewrite fmorph_eq1 => /eqP->; rewrite (Fadjoin_idP _) ?rpred1//.
    exact: rext_refl.
  + apply/(@rext_r _ _ _ n.+1)/radicalP; split => //.
    rewrite prim_expr_order ?rpred1//.
    by rewrite -(fmorph_primitive_root iota) yomega omega_prim.
- case: als1 als1E => //= a l [IHl IHlu].
  rewrite -(eq_adjoin _ (mem_rcons _ _)) adjoin_rcons.
  apply: rext_trans (IHf1 k l IHlu) _ => /=.
  move: IHlu; rewrite subevalE; case: l => // x1 l [iotax1 _].
  rewrite -iotax1 -rmorphN -fmorphV in IHl.
  have x1kx1 : x1 \in <<k & x1 :: l>>%VS by rewrite seqv_sub_adjoin ?mem_head.
  case: u => [||n|n]/= in IHl.
  + rewrite (Fadjoin_idP _); first exact: rext_refl.
    by have /fmorph_inj-> := IHl; rewrite rpredN.
  + rewrite (Fadjoin_idP _); first exact: rext_refl.
    by have /fmorph_inj-> := IHl; rewrite rpredV.
  + rewrite (Fadjoin_idP _); first exact: rext_refl.
    by have := IHl; rewrite -rmorphX => /fmorph_inj->; rewrite rpredX.
  apply/(@rext_r _ _ _ n.+1)/radicalP; split => //.
  have /(congr1 ((@GRing.exp _)^~ n.+1)) := IHl.
  by rewrite rootCK// -rmorphX => /fmorph_inj->.
- case: als1 als1E => //= a l [IHl IHlu].
  rewrite -(eq_adjoin _ (mem_rcons _ _)) adjoin_rcons.
  pose n := size (subeval ratr f1); rewrite -[l](cat_take_drop n).
  have /(congr1 (take n)) := IHlu; rewrite take_size_cat//.
  rewrite -map_take; move: (take _ _) => l1 l1E.
  have /(congr1 (drop n)) := IHlu; rewrite drop_size_cat//.
  rewrite -map_drop; move: (drop _ _) => l2 l2E.
  apply: rext_trans (IHf1 _ l1 l1E) _ => /=.
  apply: rext_trans (IHf2 _ l2 l2E) _ => /=.
  rewrite -adjoin_cat (Fadjoin_idP _); first exact: rext_refl.
  rewrite subevalE in l1E; rewrite subevalE in l2E.
  case: l1 l1E => // b1 l1 [iotab1 _].
  case: l2 l2E => // b2 l2 [iotab2 _].
  rewrite -iotab1 -iotab2 -rmorphM -rmorphD in IHl.
  have b2l : b2 \in (b1 :: l1) ++ (b2 :: l2) by rewrite mem_cat mem_head orbT.
  have b1l : b1 \in (b1 :: l1) ++ (b2 :: l2) by rewrite mem_head.
  by case: b IHl => /fmorph_inj ->; rewrite ?(rpredD, rpredM)// seqv_sub_adjoin.
Qed.

End Formula.

Module PrimeDegreeTwoNonRealRoots.
Section PrimeDegreeTwoNonRealRoots.

Variables (L : splittingFieldType rat) (iota : {rmorphism L -> algC}).
Let charL := char_ext L.

Variables (p : {poly rat}) (rp' : seq L).
Hypothesis p_irr : irreducible_poly p.
Hypothesis rp'_uniq : uniq rp'.
Hypothesis ratr_p' : map_poly ratr p = \prod_(x <- rp') ('X - x%:P).
Let d := (size p).-1.
Hypothesis d_prime : prime d.
Hypothesis count_rp' : count [pred x | iota x \isn't Num.real] rp' = 2%N.

Let rp := [seq x <- rp' | iota x \isn't Num.real]
          ++ [seq x <- rp' | iota x \is Num.real].

Let rp_perm : perm_eq rp rp'. Proof. by rewrite perm_catC perm_filterC. Qed.
Let rp_uniq : uniq rp. Proof. by rewrite (perm_uniq rp_perm). Qed.
Let ratr_p : map_poly ratr p = \prod_(x <- rp) ('X - x%:P).
Proof. by symmetry; rewrite ratr_p'; apply: perm_big. Qed.

Lemma nth_rp_real i : (iota rp`_i \is Num.real) = (i > 1)%N.
Proof.
rewrite nth_cat size_filter count_rp'; case: ltnP => // iP; [apply/negbTE|].
  apply: (allP (filter_all [predC (mem Creal) \o iota] _)) _ (mem_nth 0 _).
  by rewrite size_filter count_rp'.
have [i_big|i_small] := leqP (size [seq x <- rp' | iota x \is Creal]) (i - 2).
  by rewrite nth_default// rmorph0 rpred0.
exact: (allP (filter_all (mem Creal \o iota) _)) _ (mem_nth 0 _).
Qed.

Let K := <<1 & rp'>>%AS.
Let K_eq : K = <<1 & rp>>%AS :> {vspace _}.
Proof. exact/esym/eq_adjoin/perm_mem. Qed.

Let K_split_p : splittingFieldFor 1%AS (map_poly ratr p) K.
Proof. by exists rp => //; rewrite ratr_p eqpxx. Qed.

Let p_monic : p \is monic.
Proof.
by rewrite -(map_monic [rmorphism of char0_ratr charL]) ratr_p monic_prod_XsubC.
Qed.

Let p_sep : separable_poly p.
Proof.
rewrite -(separable_map [rmorphism of char0_ratr charL]) ratr_p.
by rewrite separable_prod_XsubC.
Qed.

Let p_neq0 : p != 0. Proof. exact: irredp_neq0. Qed.

Let d_gt0 : (d > 0)%N.
Proof. by rewrite prime_gt0. Qed.

Let d_gt1 : (d > 1)%N.
Proof. by rewrite prime_gt1. Qed.

Lemma size_rp : size rp = d.
Proof.
have /(congr1 (size \o val))/= := ratr_p; rewrite -char0_ratrE size_map_poly.
by rewrite size_prod_XsubC polySpred// => -[].
Qed.

Let i0 := Ordinal d_gt0.
Let i1 := Ordinal d_gt1.

Lemma ratr_p_over : map_poly (ratr : rat -> L) p \is a polyOver 1%AS.
Proof.
apply/polyOverP => i; rewrite -char0_ratrE coef_map /=.
by rewrite char0_ratrE -alg_num_field rpredZ ?mem1v.
Qed.

Lemma galois1K : galois 1%VS K.
Proof.
apply/splitting_galoisField; exists (map_poly ratr p); split => //.
  exact: ratr_p_over.
by rewrite -char0_ratrE separable_map.
Qed.

Lemma all_rpK : all (mem K) rp.
Proof. by rewrite K_eq; apply/allP/seqv_sub_adjoin. Qed.

Lemma root_p : root (map_poly ratr p) =i rp.
Proof. by move=> x; rewrite ratr_p [x \in root _]root_prod_XsubC. Qed.

Lemma rp_roots : all (root (map_poly ratr p)) rp.
Proof. by apply/allP => x; rewrite -root_p. Qed.

Lemma ratr_p_rp i : (i < d)%N -> (map_poly ratr p).[rp`_i] = 0.
Proof. by move=> ltid; apply/eqP; rewrite [_ == _]root_p mem_nth ?size_rp. Qed.

Lemma rpK i : (i < d)%N -> rp`_i \in K.
Proof. by move=> ltid; rewrite [_ \in _](allP all_rpK) ?mem_nth ?size_rp. Qed.

Lemma eq_size_rp : size rp == d. Proof. exact/eqP/size_rp. Qed.
Let trp := Tuple eq_size_rp.

Lemma gal_perm_eq (g : gal_of K) : perm_eq [seq g x | x <- trp] trp.
Proof.
apply: prod_XsubC_eq; rewrite -ratr_p big_map.
transitivity (map_poly (g \o ratr) p).
  rewrite map_poly_comp/= ratr_p rmorph_prod/=.
  by apply: eq_bigr => x; rewrite rmorphB/= map_polyX map_polyC/=.
apply: eq_map_poly => x /=; rewrite (fixed_gal _ (gal1 g)) ?sub1v//.
by rewrite -alg_num_field rpredZ ?mem1v.
Qed.

Definition gal_perm g : 'S_d := projT1 (sig_eqW (tuple_permP (gal_perm_eq g))).

Lemma gal_permP g i : rp`_(gal_perm g i) = g (rp`_i).
Proof.
rewrite /gal_perm; case: sig_eqW => /= s.
move=> /(congr1 (((@nth _ 0))^~ i)); rewrite (nth_map 0) ?size_rp// => ->.
by rewrite (nth_map i) ?size_enum_ord// (tnth_nth 0)/= nth_ord_enum.
Qed.

(** N/A **)
Lemma gal_perm_is_morphism :
  {in ('Gal(K / 1%AS))%G &, {morph gal_perm : x y / (x * y)%g >-> (x * y)%g}}.
Proof.
move=> u v _ _; apply/permP => i; apply/val_inj.
apply: (uniqP 0 rp_uniq); rewrite ?inE ?size_rp ?ltn_ord//=.
by rewrite permM !gal_permP galM// ?rpK.
Qed.
Canonical gal_perm_morphism :=  Morphism gal_perm_is_morphism.

Lemma minPoly_rp x : x \in rp -> minPoly 1%VS x = map_poly ratr p.
Proof.
move=> xrp; apply/eqP; rewrite -eqp_monic ?monic_minPoly//; last first.
  by rewrite ratr_p monic_prod_XsubC.
have : minPoly 1 x %| map_poly ratr p.
  by rewrite minPoly_dvdp ?ratr_p_over ?[root _ _]root_p//=.
have : size (minPoly 1 x) != 1%N by rewrite size_minPoly.
have /polyOver1P[q ->] := minPolyOver 1 x.
have /eq_map_poly -> : in_alg L =1 ratr.
  by move=> r; rewrite in_algE alg_num_field.
by rewrite -char0_ratrE /eqp !dvdp_map -/(_ %= _) size_map_poly; apply: p_irr.
Qed.

Lemma injm_gal_perm : ('injm gal_perm)%g.
Proof.
apply/subsetP => u /mker/= gu1; apply/set1gP/eqP/gal_eqP => x Kx.
have fixrp : all (fun r => frel u r r) rp.
  apply/allP => r/= /(nthP 0)[i]; rewrite size_rp => ltid <-.
  have /permP/(_ (Ordinal ltid))/(congr1 val)/= := gu1.
  by rewrite perm1/= => {2}<-; rewrite gal_permP.
rewrite K_eq /= in Kx.
elim/last_ind: rp x Kx fixrp => [|s r IHs] x.
  rewrite adjoin_nil subfield_closed => x1 _.
  by rewrite (fixed_gal _ (gal1 u)) ?sub1v ?gal_id.
rewrite adjoin_rcons => /Fadjoin_poly_eq <-.
rewrite all_rcons => /andP[/eqP ur /IHs us].
rewrite gal_id -horner_map/= ur map_poly_id//=.
move=> a /(nthP 0)[i i_lt <-]; rewrite us ?gal_id//.
exact/polyOverP/Fadjoin_polyOver.
Qed.

Lemma dvd_dG : (d %| #|'Gal(K / 1%VS)%g|)%N.
Proof.
rewrite dim_fixedField (galois_fixedField _) ?galois1K ?dimv1 ?divn1//.
rewrite (@dvdn_trans (\dim_(1%VS : {vspace L}) <<1; rp`_0>>%VS))//.
  rewrite -adjoin_degreeE -[X in (_ %| X)%N]/(_.+1.-1).
  rewrite -size_minPoly minPoly_rp ?mem_nth ?size_rp//.
  by rewrite -char0_ratrE size_map_poly.
rewrite dimv1 divn1 K_eq field_dimS//= -adjoin_seq1 adjoin_seqSr//.
have: (0 < size rp)%N by rewrite size_rp.
by case: rp => //= x l _ y; rewrite inE => /eqP->; rewrite inE eqxx.
Qed.

Definition gal_cycle : gal_of K := projT1 (Cauchy d_prime dvd_dG).

Lemma gal_cycle_order : #[gal_cycle]%g = d.
Proof. by rewrite /gal_cycle; case: Cauchy. Qed.

Lemma gal_perm_cycle_order : #[(gal_perm gal_cycle)]%g = d.
Proof. by rewrite order_injm ?gal_cycle_order ?injm_gal_perm ?gal1. Qed.

Definition conjL : {lrmorphism L -> L} :=
  projT1 (restrict_aut_to_normal_num_field iota conjC).

Definition iotaJ : {morph iota : x / conjL x >-> x^*} :=
  projT2 (restrict_aut_to_normal_num_field _ _).

Lemma conjLK : involutive conjL.
Proof. by move=> x; apply: (fmorph_inj iota); rewrite !iotaJ conjCK. Qed.

Lemma conjL_rp : {mono conjL : x / x \in rp}.
Proof.
suff rpJ : {homo conjL : x / x \in rp}.
  by move=> x; apply/idP/idP => /rpJ//; rewrite conjLK.
move=> ?/(nthP 0)[i]; rewrite size_rp => ltid <-.
rewrite -!root_p -!topredE /root/=.
have /eq_map_poly<- : conjL \o char0_ratr charL =1 _ := fmorph_eq_rat _.
by rewrite map_poly_comp horner_map ratr_p_rp ?rmorph0.
Qed.

Lemma conjL_K : {mono conjL : x / x \in K}.
Proof.
suff rpJ : {homo conjL : x / x \in K}.
  by move=> x; apply/idP/idP => /rpJ//; rewrite conjLK.
move=> x; rewrite K_eq => xK.
have : conjL x \in (linfun conjL @:  <<1 & rp>>)%VS.
  by apply/memv_imgP; exists x => //; rewrite lfunE.
rewrite aimg_adjoin_seq aimg1/= (@eq_adjoin _ _ _ _ rp)// => y.
apply/mapP/idP => [[z zrp->]|yrp]; first by rewrite lfunE conjL_rp.
by exists (conjL y); rewrite ?conjL_rp//= !lfunE [RHS]conjLK.
Qed.

Lemma conj_rp0 : conjL rp`_i0 = rp`_i1.
Proof.
have /(nthP 0)[j jlt /esym rpj_eq]: conjL rp`_i0 \in rp.
  by rewrite conjL_rp mem_nth ?size_rp.
rewrite size_rp in jlt; rewrite rpj_eq; congr nth.
have: j != i0.
  apply: contra_eq_neq rpj_eq => ->.
  by rewrite -(inj_eq (fmorph_inj iota)) iotaJ -CrealE nth_rp_real.
have: (j < 2)%N by rewrite ltnNge -nth_rp_real -rpj_eq iotaJ CrealJ nth_rp_real.
by case: j {jlt rpj_eq} => [|[|[]]].
Qed.

Lemma conj_rp1 : conjL rp`_i1 = rp`_i0.
Proof. by apply: (canLR conjLK); rewrite conj_rp0. Qed.

Lemma conj_nth_rp (i : 'I_d) : conjL (rp`_i) = rp`_(tperm i0 i1 i).
Proof.
rewrite permE/=; case: eqVneq => [->|Ni0]; first by rewrite conj_rp0.
case: eqVneq => [->|Ni1]; first by rewrite conj_rp1.
have i_gt : (i > 1)%N by case: i Ni0 Ni1 => [[|[|[]]]].
apply: (fmorph_inj iota); rewrite iotaJ.
by rewrite conj_Creal ?nth_rp_real// tpermD// -val_eqE/= ltn_eqF// ltnW.
Qed.

Definition galJ : gal_of K := gal K (AHom (linfun_is_ahom conjL)).

Lemma galJ_tperm : gal_perm galJ = tperm i0 i1.
Proof.
apply/permP => i; apply/val_inj.
apply: (uniqP 0 rp_uniq); rewrite ?inE ?size_rp ?ltn_ord//=.
rewrite gal_permP /galJ/= galK ?rpK//= ?lfunE ?[LHS]conj_nth_rp//.
by apply/subvP => /= _/memv_imgP[x Ex ->]; rewrite lfunE conjL_K.
Qed.

Lemma surj_gal_perm : (gal_perm @* 'Gal (K / 1%AS) = 'Sym_('I_d))%g.
Proof.
apply/eqP; rewrite eqEsubset subsetT/=.
rewrite -(@gen_tperm_cycle _ i0 i1 (gal_perm gal_cycle));
  do ?by rewrite ?dpair_ij0 ?card_ord ?gal_perm_cycle_order.
 rewrite gen_subG; apply/subsetP => s /set2P[]->;
   rewrite -?galJ_tperm ?mem_morphim ?gal1//.
Qed.

Lemma isog_gal_perm : 'Gal (K / 1%AS) \isog ('Sym_('I_d)).
Proof.
apply/isogP; exists gal_perm_morphism; first exact: injm_gal_perm.
exact: surj_gal_perm.
Qed.

End PrimeDegreeTwoNonRealRoots.
End PrimeDegreeTwoNonRealRoots.
Module PDTNRR := PrimeDegreeTwoNonRealRoots.

Section Example1.

Definition poly_example_int : {poly int} := 'X^5 - 4 *: 'X + 2.
Definition poly_example : {poly rat} := 'X^5 - 4 *: 'X + 2.

Local Definition pesimp := (coefD, coefN, coefB, coefZ, coefXn, coefX, coefC,
  hornerD, hornerN, hornerC, hornerZ, hornerX, hornerXn, rmorph_nat).

Lemma polyCn (R : ringType) n : n%:R%:P = n%:R :> {poly R}.
Proof. by rewrite rmorph_nat. Qed.

Lemma poly_exampleEint : poly_example = map_poly intr poly_example_int.
Proof.
pose simp := (rmorphB, rmorphD, map_polyZ, map_polyXn, map_polyX, map_polyC).
by do !rewrite [map_poly _ _]simp/= ?natz.
Qed.

Lemma size_poly_example_int : size poly_example_int = 6.
Proof.
rewrite /poly_example_int -addrA size_addl ?size_polyXn//.
by rewrite size_addl ?size_opp ?size_scale ?size_polyX -?polyCn ?size_polyC.
Qed.

Lemma size_poly_example : size poly_example = 6.
Proof.
rewrite /poly_example -addrA size_addl ?size_polyXn//.
by rewrite size_addl ?size_opp ?size_scale ?size_polyX -?polyCn ?size_polyC.
Qed.

Lemma poly_example_int_neq0 : poly_example_int != 0.
Proof. by rewrite -size_poly_eq0 size_poly_example_int. Qed.

Lemma poly_example_neq0 : poly_example != 0.
Proof. by rewrite -size_poly_eq0 size_poly_example. Qed.
Hint Resolve poly_example_neq0 : core.

Lemma poly_example_monic : poly_example \is monic.
Proof. by rewrite monicE lead_coefE !pesimp size_poly_example. Qed.
Hint Resolve poly_example_monic : core.

Lemma irreducible_example : irreducible_poly poly_example.
Proof.
rewrite poly_exampleEint; apply: (@eisenstein 2) => // [|||i];
  rewrite ?lead_coefE ?size_poly_example_int ?pesimp//.
by move: i; do 6!case=> //.
Qed.
Hint Resolve irreducible_example : core.

Lemma separable_example : separable_poly poly_example.
Proof.
apply/coprimepP => q /(irredp_XsubCP irreducible_example) [//| eqq].
have size_deriv_example : size poly_example^`() = 5%N.
  rewrite !derivCE addr0 alg_polyC -scaler_nat addr0.
  by rewrite size_addl ?size_scale ?size_opp ?size_polyXn ?size_polyC.
rewrite gtNdvdp -?size_poly_eq0 ?size_deriv_example//.
by rewrite (eqp_size eqq) ?size_poly_example.
Qed.
Hint Resolve separable_example : core.

Lemma prime_example : prime (size poly_example).-1.
Proof. by rewrite size_poly_example. Qed.

(* Using the package real_closed, we should be able to monitor the sign of    *)
(* the derivative, and find that the polynomial has exactly three real roots. *)
Definition example_roots :=
  sval (closed_field_poly_normal ((map_poly ratr poly_example) : {poly algC})).

Lemma ratr_example_poly :
  poly_example ^^ ratr = \prod_(x <- example_roots) ('X - x%:P).
Proof.
rewrite /example_roots; case: closed_field_poly_normal => //= rs ->.
by rewrite lead_coef_map/= (eqP poly_example_monic) rmorph1 scale1r.
Qed.

Lemma size_example_roots : size example_roots = 5%N.
Proof.
have /(congr1 (fun p : {poly _} => size p)) := ratr_example_poly.
by rewrite size_map_poly size_poly_example size_prod_XsubC => -[].
Qed.

Lemma example_roots_uniq : uniq example_roots.
Proof.
rewrite -separable_prod_XsubC -ratr_example_poly.
by rewrite separable_map separable_example.
Qed.

Lemma deriv_poly_example : poly_example^`() = 5%:R *: 'X^4 - 4%:R%:P.
Proof. by rewrite /poly_example !derivE addr0 alg_polyC scaler_nat ?addr0. Qed.

Lemma deriv_poly_example_neq0 : poly_example^`() != 0.
Proof.
apply/eqP => /(congr1 (fun p => p.[0])).
by rewrite deriv_poly_example !pesimp => /eqP; compute.
Qed.
Hint Resolve deriv_poly_example_neq0 : core.

Definition alpha : algR := Num.sqrt (2%:R / Num.sqrt 5%:R).

Lemma alpha_gt0 : alpha > 0.
Proof. by rewrite sqrtr_gt0 mulr_gt0 ?invr_gt0 ?sqrtr_gt0 ?ltr0n. Qed.

Lemma rootsR_deriv_poly_example :
  rootsR (poly_example^`() ^^ ratr) = [:: - alpha; alpha].
Proof.
apply: eq_sorted_lt; rewrite ?sorted_roots//.
 by rewrite /= andbT -subr_gt0 opprK ?addr_gt0 ?alpha_gt0.
move=> x; rewrite mem_rootsR ?map_poly_eq0// !inE -topredE/= orbC.
rewrite deriv_poly_example /root.
rewrite rmorphB linearZ/= map_polyC/= map_polyXn !pesimp.
rewrite -[5%:R]sqr_sqrtr ?ler0n// (exprM _ 2 2) -exprMn (natrX _ 2 2) subr_sqr.
rewrite mulf_eq0 [_ + 2%:R == 0]gt_eqF ?orbF; last first.
  by rewrite ltr_spaddr ?ltr0n// mulr_ge0 ?sqrtr_ge0// exprn_even_ge0.
have sqrt5N0 : Num.sqrt (5%:R : algR) != 0 by rewrite gt_eqF// sqrtr_gt0 ?ltr0n.
rewrite subr_eq0 (can2_eq (mulKf _) (mulVKf _))// mulrC -subr_eq0.
rewrite -[X in _ - X]sqr_sqrtr; last first.
  by rewrite mulr_ge0 ?invr_ge0 ?sqrtr_ge0 ?ler0n.
by rewrite subr_sqr mulf_eq0 subr_eq0 addr_eq0.
Qed.

Lemma count_roots_ex : count [predC Creal] example_roots = 2%N.
Proof.
rewrite -!sum1_count; pose pR : {poly algR} := poly_example ^^ ratr.
have pR0 : pR != 0 by rewrite map_poly_eq0.
suff cR : (\sum_(j <- example_roots | j \is Num.real) 1)%N = 3%N.
  have := size_example_roots; rewrite -sum1_size (bigID (mem Num.real))/=.
  by rewrite cR => -[->].
rewrite -big_filter (perm_big (map algRval (rootsR pR))); last first.
  rewrite uniq_perm ?filter_uniq ?example_roots_uniq//.
    by rewrite (map_inj_uniq (fmorph_inj _)) uniq_roots.
  move=> x; rewrite mem_filter -root_prod_XsubC -ratr_example_poly.
  rewrite -(eq_map_poly (fmorph_eq_rat [rmorphism of algRval \o ratr]))/=.
  rewrite map_poly_comp/=.
  apply/andP/mapP => [[xR xroot]|[y + ->]].
    exists (in_algR xR); rewrite // mem_rootsR// -topredE/=.
    by rewrite -(mapf_root algRval_rmorphism)/=.
  rewrite mem_rootsR// -[y \in _]topredE/=.
  by split; [apply/algRvalP|rewrite mapf_root].
apply/eqP; rewrite sum1_size size_map eqn_leq.
rewrite (leq_trans (size_root_leSderiv _))//=; last first.
  by rewrite deriv_map rootsR_deriv_poly_example.
have pRE x : Num.sg pR.[x%:~R] = locked ratr (Num.sg poly_example.[x%:~R]).
  by rewrite -lock ratr_sg -horner_map/= ratr_int.
have pN2 : Num.sg pR.[(- 2%:Z)%:~R] = - 1 by rewrite pRE !pesimp -lock rmorphN1.
have pN1 : Num.sg pR.[(- 1%:Z)%:~R] =   1 by rewrite pRE !pesimp -lock rmorph1.
have p1  : Num.sg pR.[1%:~R]        = - 1 by rewrite pRE !pesimp -lock rmorphN1.
have p2  : Num.sg pR.[2%:~R]        =   1 by rewrite pRE !pesimp -lock rmorph1.
have simp := (pN2, pN1, p1, p2, mulN1r, mulrN1).
have [||x0 /andP[_ x0N1] rx0] := @ivt_sign _ pR (- 2%:R) (- 1); rewrite ?simp//.
  by rewrite -subr_ge0 opprK addKr ler01.
have [||x1 /andP[x10 x11] rx1] := @ivt_sign _ pR (-1) 1; rewrite ?simp//.
  by rewrite -subr_ge0 opprK addr_ge0 ?ler01.
have [||x2 /andP[/= x21 _] rx2] := @ivt_sign _ pR 1 2%:R; rewrite ?simp//.
  by rewrite -subr_ge0 addrK ler01.
have: sorted <%R [:: x0; x1; x2] by rewrite /= (lt_trans x0N1) ?(lt_trans x11).
rewrite lt_sorted_uniq_le => /andP[uniqx012 _].
apply: (@uniq_leq_size _ [:: x0; x1; x2]) => //.
by move=> x; rewrite !inE => /or3P[]/eqP->/=; rewrite mem_rootsR.
Qed.

Lemma example_not_solvable_by_radicals :
  ~ solvable_by_radical_poly ('X^5 - 4 *: 'X + 2 : {poly rat}).
Proof.
move=> /(solvable_poly_rat poly_example_neq0)[L [iota [rs []]]].
have charL := char_ext L.
rewrite (eq_map_poly (fmorph_eq_rat _)) -char0_ratrE.
rewrite eqp_monic ?map_monic ?poly_example_monic ?monic_prod_XsubC//.
move=> /eqP poly_ex_eq_prod.
have perm_rs : perm_eq (map iota rs) example_roots.
  apply: prod_XsubC_eq; rewrite -ratr_example_poly -map_prod_XsubC.
  by rewrite -poly_ex_eq_prod -map_poly_comp (eq_map_poly (fmorph_eq_rat _)).
have rs_uniq : uniq rs.
  rewrite -separable_prod_XsubC -poly_ex_eq_prod.
  by rewrite separable_map separable_example.
move=> /(radical_solvable_ext charL (sub1v _)) /=.
have gal1rs : galois 1 <<1 & rs>> by apply: (@PDTNRR.galois1K _ iota poly_example).
rewrite /solvable_ext minGalois_id//.
have := PDTNRR.isog_gal_perm irreducible_example rs_uniq poly_ex_eq_prod _.
move=> /(_ iota); rewrite size_poly_example => /(_ isT)/(_ _)/isog_sol->//.
  by move=> /andP[_ /not_solvable_Sym]; rewrite card_ord/=; apply.
by rewrite -(count_map _ [predC Creal]) (seq.permP perm_rs) count_roots_ex.
Qed.

End Example1.
