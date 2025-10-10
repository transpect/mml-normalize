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
  
  <p:output port="result" primary="true">
    <p:documentation>
      The input document with @alttext attributes added
    </p:documentation>
  </p:output>
  
  <p:output port="processing-info" primary="false">
    <p:documentation>
      Processing info ('version-nr' children element: used SRE version number)
    </p:documentation>
    <p:pipe step="processing-info" port="result"/>
  </p:output>
  
  <p:option name="lang" select="'en'"/>
  <p:option name="sre-path" select="'/home/wbdvadmin/node_modules/speech-rule-engine/bin/sre'"/>
  <p:option name="insert-tr-processing-attr" select="'yes'"/>
  
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
  
  <p:group name="processing-info">
    <p:output port="result"/>
    <p:variable name="run" select="/c:result/@os-path">
      <p:pipe port="result" step="get-sre-path"/>
    </p:variable>
    <p:try>
      <p:group>
        <p:exec result-is-xml="false" errors-is-xml="false" wrap-result-lines="true" name="get-sre-version">
          <p:input port="source">
            <p:empty/>
          </p:input>
          <p:with-option name="command" select="$run"/>
          <p:with-option name="args" select="'-V'"/>
        </p:exec>
        <p:rename match="c:result" new-name="version-nr"/>
        <p:wrap match="version-nr" wrapper="c:result"/>
      </p:group>
      <p:catch>
        <p:identity>
          <p:input port="source">
            <p:inline>
              <c:result><version-nr>undefined</version-nr></c:result>  
            </p:inline>  
          </p:input>
        </p:identity>
      </p:catch>
    </p:try>
    </p:group>
  
  <p:sink/>
  
  <p:identity>
    <p:input port="source">
      <p:pipe port="source" step="mml-add-alttext"/>
    </p:input>
  </p:identity>
  
  <p:group name="main">
    <p:variable name="run" select="/c:result/@os-path">
      <p:pipe port="result" step="get-sre-path"/>
    </p:variable>
    <p:variable name="args" select="concat('-c ', $lang)"/>
    
    <cx:message>
      <p:with-option name="message" select="concat('[info]: run SRE: ', $run, ' ', $args)"/>
    </cx:message>
    
    <p:viewport match="mml:math[not(@alttext)]" name="math-view">
      
      <!-- the equation is passed to stdin -->
      
      <p:try>
        <p:group>
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
          <p:choose>
            <p:when test="$insert-tr-processing-attr = 'yes'">
              <p:add-attribute match="mml:math" attribute-name="tr:alttext" attribute-value="ok"/>
            </p:when>
            <p:otherwise>
              <p:identity/>
            </p:otherwise>
          </p:choose>
        </p:group>
        <p:catch>
          
          <p:identity>
            <p:input port="source">
              <p:pipe port="current" step="math-view"/>
            </p:input>
          </p:identity>
          <p:choose>
            <p:when test="$insert-tr-processing-attr = 'yes'">
              <p:add-attribute match="mml:math" attribute-name="tr:alttext" attribute-value="ok"/>
              <p:add-attribute match="mml:math" attribute-name="alttext" attribute-value="fake-alttext-for-test"/>
            </p:when>
            <p:otherwise>
              <p:identity/>
            </p:otherwise>
          </p:choose>
          
        </p:catch>
      </p:try>
      
    </p:viewport>
    
  </p:group>
  
</p:declare-step>