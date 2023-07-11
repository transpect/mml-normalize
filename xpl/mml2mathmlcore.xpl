<?xml version="1.0" encoding="utf-8"?>
<p:declare-step
  xmlns:p="http://www.w3.org/ns/xproc" 
  xmlns:c="http://www.w3.org/ns/xproc-step"  
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:tr="http://transpect.io"
  version="1.0"
  name="mml2mathmlcore"
  type="tr:mml2mathmlcore">
  
  <p:documentation>XProc step to convert any MathML formula to MathML-Core.</p:documentation>
  
  <p:input port="source" primary="true">
    <p:documentation>Document with MathML formulas.</p:documentation>
  </p:input>
  <p:input port="stylesheet">
    <p:document href="../xsl/mml2mathmlcore.xsl"/>
  </p:input>
  <p:output port="result" primary="true"/>

  <p:option name="to-version" select="'4-core'"/>
  <p:option name="from-version" select="'any'"/>
  <p:option name="keep-mml-prefix" select="'any'">
    <p:documentation>Keep and add mml-prefix (all) or dissolve prefix (none)</p:documentation>
  </p:option>

  <p:xslt initial-mode="mml-to-core">
    <p:with-param name="to-version" select="$to-version"/>
    <p:with-param name="from-version" select="$from-version"/>
    <p:input port="stylesheet">
      <p:pipe port="stylesheet" step="mml2mathmlcore"/>
    </p:input>
    <p:input port="parameters"><p:empty/></p:input>
  </p:xslt>
  
  <p:xslt initial-mode="mml-prefix">
    <p:with-param name="keep-mml-prefix" select="$keep-mml-prefix"/>
    <p:input port="stylesheet">
      <p:pipe port="stylesheet" step="mml2mathmlcore"/>
    </p:input>
    <p:input port="parameters"><p:empty/></p:input>
  </p:xslt>
  
</p:declare-step>