OCAMLC = ocamlc
OCAMLOPT = ocamlopt

LIB_SRC = src/help_tree
LIB_CMO = $(LIB_SRC).cmo
LIB_CMX = $(LIB_SRC).cmx

EXAMPLES = basic deep hidden

.PHONY: all clean $(EXAMPLES)

all: $(EXAMPLES)

$(LIB_CMO): $(LIB_SRC).mli $(LIB_SRC).ml
	cd src && $(OCAMLC) -c help_tree.mli
	cd src && $(OCAMLC) -I +unix -c help_tree.ml

$(LIB_CMX): $(LIB_SRC).mli $(LIB_SRC).ml
	cd src && $(OCAMLOPT) -c help_tree.mli
	cd src && $(OCAMLOPT) -I +unix -c help_tree.ml

UNIX_LIB = -I +unix unix.cma
UNIX_LIB_OPT = -I +unix unix.cmxa

basic: $(LIB_CMO) examples/basic.ml
	$(OCAMLC) -I src $(UNIX_LIB) -o examples/basic $(LIB_CMO) examples/basic.ml

deep: $(LIB_CMO) examples/deep.ml
	$(OCAMLC) -I src $(UNIX_LIB) -o examples/deep $(LIB_CMO) examples/deep.ml

hidden: $(LIB_CMO) examples/hidden.ml
	$(OCAMLC) -I src $(UNIX_LIB) -o examples/hidden $(LIB_CMO) examples/hidden.ml

native: $(LIB_CMX)
	$(OCAMLOPT) -I src $(UNIX_LIB_OPT) -o examples/basic $(LIB_CMX) examples/basic.ml
	$(OCAMLOPT) -I src $(UNIX_LIB_OPT) -o examples/deep $(LIB_CMX) examples/deep.ml
	$(OCAMLOPT) -I src $(UNIX_LIB_OPT) -o examples/hidden $(LIB_CMX) examples/hidden.ml

clean:
	rm -f src/*.cmi src/*.cmo src/*.cmx src/*.o
	rm -f examples/basic examples/deep examples/hidden
