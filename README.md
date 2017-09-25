# mathml-normalize

An XSLT library to normalize MathML equations with heuristic methods.

## Description

The authoring of math equations is an error-prone process, especially with WYSIWYG editors such as MathType and Microsoft Word Equation Editor. For example, authors tend to write symbols accidentally in text mode instead of changing the font-style to normal. This causes that the symbol later appears in MathML as `mtext` and not as `mi`.

Consider this MathML equation with wrong markup:

```xml
<math xmlns="http://www.w3.org/1998/Math/MathML">
  <mtext>E=m</mtext>
  <msubsup>
    <mtext>c</mtext>
    <mi>&#x2009;</mi>
    <mn>2</mn>
  </msubsup>
</math>
```

After mml-normalize, the `mtext` was resolved and the text was properly tagged with `mi` and `mo` elements. Furthermore, the `msubsup` was replaced with `msup`

```xml
<math xmlns="http://www.w3.org/1998/Math/MathML" xmlns:xlink="http://www.w3.org/1999/xlink">
  <mrow>
    <mi mathvariant="normal">E</mi>
    <mo>=</mo>
    <mi mathvariant="normal">m</mi>
  </mrow>
  <msup>
    <mi mathvariant="normal">c</mi>
    <mn>2</mn>
  </msup>
</math>
```

## Invoke with Saxon

mml-normalize contains two XSLT modes. First, you should invoke `mml2tex-grouping` and afterwards `mml2tex-preprocess`.

```
$ saxon -xsl:mml-normalize/xsl/mml-normalize.xsl -s:eq.xml -o:eq-nrmlzd.xml -im:mml2tex-grouping
$ saxon -xsl:mml-normalize/xsl/mml-normalize.xsl -s:eq.xml -o:eq-nrmlzd.xml -im:mml2tex-preprocess

```
