# Gates via exponentiated Hamiltonians

This document describes an extension to the Quil standard which allows gates to be described by an associated Hamiltonian, as in $$U(\mathbf t) = \exp(-i \mathcal H(\mathbf t))$$ for a Hermitian operator $$\mathcal H$$.

## Examples

Many standard examples of gates admit short expression in these terms:

```
DEFGATE RY(%theta) q AS PAULI-SUM:
    Y(-%theta/2) q
```

This includes many standard multi-qubit operators:

```
DEFGATE CPHASE(%theta) p q AS PAULI-SUM:
    ZZ(-%theta/4) p q
    Z(%theta/4) p
    Z(%theta/4) q
```

It also includes some less standard multi-qubit operators:

```
DEFGATE CAN(%alpha, %beta, %gamma) p q AS PAULI-SUM:
    XX(%alpha/4) p q
    YY(%beta/4)  p q
    ZZ(%gamma/4) p q
```

It also includes some operators encountered in practice, e.g., the following reduction of an Ansatz appearing in the electronic structure simulation problem for $$\mathrm H_2$$:

```
DEFGATE UCC-H2(%theta) p q r s AS PAULI-SUM:
    YXXX(%theta) p q r s
```

### Design principles

We do not want the gate presentation to grow quickly with the qubit count. For this reason, we have adopted the following principles:

* Any omitted Pauli word is understood to have coefficient 0.
* Any omitted qubit formal from a given Pauli word is understood to be acted upon by the identity.  In practice, this requires that we give the qubits explicit names, so that Pauli is being elided can be discerned.

## Technical specification

### Syntax

```
DEFGATE IDENTIFIER PARAM-LIST? QUBIT-LIST AS PAULI-SUM:
[    PAULI-WORD(EXPRESSION) QUBIT-LIST]+
```
where `DEFGATE`, `AS`, `PAULI-SUM` are all literals, `IDENTIFIER` names a Quil identifier, `EXPRESSION` names a Quil expression, and the other tokens are defined by

```
PAULI-WORD = [IXYZ]+
QUBIT-LIST = FORMAL-QUBIT[ FORMAL-QUBIT]*
PARAM-LIST = (FORMAL-PARAM[, FORMAL-PARAM]*)
```

### Parse-time restrictions

`EXPRESSION` names a real-valued expression which references only real literals and the parameter list.

Qubits appearing in a Pauli term's `QUBIT-LIST` must only reference formals appearing in the header's `QUBIT-LIST`, and no qubits may be repeated.

The length of a Pauli term's `QUBIT-LIST` must agree with the number of letters in the term's `PAULI-WORD`.

### Semantics

We describe how one is intended to extract a matrix presentation of an operator from such a Pauli sum, and then we remit the discussion of semantics to that for `DEFGATE ... AS MATRIX`.

1. Pad each Pauli word appearing in the sum with `I` letters, so that all formal qubits appear in all terms.
2. Sort the qubit arguments appearing in each term to agree with the qubit argument list in the definition header. Simultaneously, sort the letters appearing in the Pauli word to match.
3. Using the definitions $$I = \left( \begin{array}{cc} 1 & 0 \\ 0 & 1 \end{array} \right)$$, $$X = \left( \begin{array}{cc} 0 & 1 \\ 1 & 0 \end{array} \right)$$, $$Y = \left( \begin{array}{cc} 0 & -i \\ i & 0 \end{array} \right)$$, $$Z = \left( \begin{array}{cc} 1 & 0 \\ 0 & -1 \end{array} \right)$$, associate to each Pauli term's Pauli word the ordered tensor product of these basic matrices.
4. Scale each such matrix by the Pauli term's `EXPRESSION`.
5. Sum the matrices, multiply by $$i$$, and form the matrix exponential.

#### Example of semantic reduction

In the example definition of `CPHASE` above, these steps proceed as follows:

1. We replace `ZZ p q; Z p; Z q` by `ZZ p q; ZI p q; ZI q p`, which each now apply to all the available formal qubits.
2. We replace `ZZ p q; ZI p q; ZI q p` by `ZZ p q; ZI p q; IZ p q`, which now all end in `p q`.
3. The tensor products associated to these three terms are respectively $$ZZ = \left( \begin{array}{cccc}1 \\ & -1 \\ & & -1 \\ & & & 1 \end{array} \right)$$, $$ZI = \left( \begin{array}{cccc}1 \\ & 1 \\ & & -1 \\ & & & -1 \end{array} \right)$$, $$IZ = \left( \begin{array}{cccc}1 \\ & -1 \\ & & 1 \\ & & & -1 \end{array} \right)$$, where we have elided zero entries.
4. After rescaling by the associated expressions, these matrices become $$\left( \begin{array}{cccc}-\theta/4 \\ & \theta/4 \\ & & \theta/4 \\ & & & -\theta/4 \end{array} \right)$$, $$\left( \begin{array}{cccc}\theta/4 \\ & \theta/4 \\ & & -\theta/4 \\ & & & -\theta/4 \end{array} \right)$$, and $$\left( \begin{array}{cccc}\theta/4 \\ & -\theta/4 \\ & & \theta/4 \\ & & & -\theta/4 \end{array} \right)$$.
5. Taking the sum and multiplying by $$i$$ yields $$\left( \begin{array}{cccc}i\theta/4 \\ & i\theta/4 \\ & & i\theta/4 \\ & & & -3i\theta/4 \end{array} \right)$$, and exponentiating yields $$\mathrm{CPHASE}(\theta) = \left( \begin{array}{cccc}e^{i\theta/4} \\ & e^{i\theta/4} \\ & & e^{i\theta/4} \\ & & & e^{-3i\theta/4} \end{array} \right)$$.

Up to global phase, this is evidently equivalent to the usual `... AS MATRIX` definition:

```
DEFGATE CPHASE(%theta) AS MATRIX:
    1, 0, 0, 0
    0, 1, 0, 0
    0, 0, 1, 0
    0, 0, 0, cis(-%theta)
```