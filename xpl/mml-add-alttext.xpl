<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc"
  xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:cx="http://xmlcalabash.com/ns/extensions"
  xmlns:pos="http://exproc.org/proposed/steps/os"
  xmlns:mml="http://www.w3.org/1998/Math/MathML"
  xmlns:tr="http://transpect.io"
  version="1.0"
  name="mml-add-alttext"
  type="tr:mml-add-alttext">
  
  <p:documentation>
    This step takes XML documents with MathML and 
    adds to each MathML equation an alt text attribute.
  </p:documentation>
  
  <p:input port="source">
    <p:documentation>
      Expects an arbitrary XML document with MathML equations
    </p:documentation>
  </p:input>  
    
  <p:output port="result">
    <p:documentation>
      The input document but with @alttext attributes for equations
    </p:documentation>
  </p:output>

  <p:option name="lang" select="'en'"/>
  <p:option name="sre-path" select="'/home/wbdvadmin/node_modules/speech-rule-engine/bin/sre'"/>

  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
  <p:import href="http://transpect.io/xproc-util/file-uri/xpl/file-uri.xpl"/>
  
  <tr:file-uri name="get-sre-path">
    <p:with-option name="filename" select="$sre-path"/>
    <p:input port="catalog">
      <p:document href="http://this.transpect.io/xmlcatalog/catalog.xml"/>
    </p:input>
    <p:input port="resolver">
      <p:document href="http://transpect.io/xslt-util/xslt-based-catalog-resolver/xsl/resolve-uri-by-catalog.xsl"/>
    </p:input>
  </tr:file-uri>
  
  <p:sink/>
  
  <p:identity>
    <p:input port="source">
      <p:pipe port="source" step="mml-add-alttext"/>
    </p:input>
  </p:identity>
  
  <p:group>
    <p:variable name="run" select="/c:result/@os-path">
      <p:pipe port="result" step="get-sre-path"/>
    </p:variable>
    
    <p:viewport match="mml:math" name="math-view">
      <p:variable name="args" select="concat('-c ', $lang)"/>
      
      <cx:message>
        <p:with-option name="message" select="concat('[info]: ', $run, ' ', $args)"/>
      </cx:message>
      
      <!-- the equation is passed to stdin -->
      
      <p:exec result-is-xml="false" errors-is-xml="false" wrap-result-lines="true" name="get-alttext">
        <p:input port="source">
          <p:pipe port="current" step="math-view"/>
        </p:input>
        <p:with-option name="command" select="$run"/>
        <p:with-option name="args" select="$args"/>
      </p:exec>
      
      <p:add-attribute match="mml:math" attribute-name="alttext">
        <p:input port="source">
          <p:pipe port="current" step="math-view"/>
        </p:input>
        <p:with-option name="attribute-value" select="normalize-space(/c:result/c:line)">
          <p:pipe port="result" step="get-alttext"/>
        </p:with-option>
      </p:add-attribute>
      
    </p:viewport>
    
  </p:group>
  
</p:declare-step>