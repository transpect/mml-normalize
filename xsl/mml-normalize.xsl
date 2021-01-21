<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:mml="http://www.w3.org/1998/Math/MathML"
  xmlns:mml2tex="http://transpect.io/mml2tex"
  xmlns="http://www.w3.org/1998/Math/MathML"
  version="2.0"
  exclude-result-prefixes="#all" 
  xpath-default-namespace="http://www.w3.org/1998/Math/MathML">
  <!--  *
        * remove empty equation objects
        * -->
  
  <xsl:import href="operators.xsl"/>
  <xsl:import href="function-names.xsl"/>

  <xsl:param name="remove-mspace-treshold-em" select="0.16" as="xs:decimal"/>
  <xsl:param name="chars-from-which-to-convert-mi-to-mtext" select="5" as="xs:integer"/>

  <xsl:variable name="whitespace-regex" select="'\p{Zs}&#x200b;-&#x200f;'" as="xs:string"/>
  <xsl:variable name="wrapper-element-names" select="('msup', 
                                                      'msub', 
                                                      'msubsup', 
                                                      'mfrac', 
                                                      'mroot', 
                                                      'mmultiscripts', 
                                                      'mover', 
                                                      'munder', 
                                                      'munderover')" as="xs:string+"/>
  <xsl:variable name="sil-units-regex" select="'(m|g|s|A|K|mol|cd|rad|sr|GHz|Hz|N|Nm|Pa|J|W|C|V|F|Ω|S|Wb|T|H|°|°C|lm|lx|Bq|Gy|Sv|kat)'" as="xs:string"/>
  <xsl:variable name="sil-unit-prefixes-regex" select="'(G|M|k|d|c|m|µ|n|p|f)'" as="xs:string"/>
  <xsl:variable name="greek-chars-regex" select="'[&#x393;-&#x3f5;]'" as="xs:string"/>
  
  <xsl:template match="mml:math[every $i in .//mml:* 
                                satisfies (string-length(normalize-space($i)) eq 0 and not($i/@*))]
                       |//processing-instruction('mathtype')[string-length(normalize-space(replace(., '\$', ''))) eq 0]" mode="mml2tex-preprocess">
    <xsl:message select="'[WARNING] empty equation removed:&#xa;', ."/>
  </xsl:template>
  
  <!--  *
        * group adjacent mi and mtext tags with equivalent attributes
        * -->
  
  <xsl:template match="*[   count(mi) gt 1 
                         or count(mtext) gt 1 
                         or count(mspace) gt 1]
                        [not(local-name() = $wrapper-element-names)]" mode="mml2tex-grouping">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:for-each-group select="*" 
        group-adjacent="concat(local-name(),
                               string-join(for $i in @* except (@xml:space|@width) 
                                           return concat($i/local-name(), $i), '-'),
                               matches(., concat('^[\p{L}\p{P}', $whitespace-regex, ']+$'), 'i') or self::mspace[not(@linebreak)],
                               matches(., concat('^', $mml2tex:functions-names-regex, '$')),
                               matches(., concat('^', $greek-chars-regex, '$'))
                               )">
          <xsl:choose>
            <xsl:when test="current-group()/self::mi[every $i in 1 to ($chars-from-which-to-convert-mi-to-mtext - 1) 
                                                     satisfies following-sibling::*[$i]/local-name() eq 'mi']">
              <xsl:element name="mtext">
              <xsl:attribute name="mathvariant" select="(@mathvariant, 'italic')[1]"/>
                <xsl:if test="not(every $i in current-group()/@mathvariant 
                                  satisfies $i eq 'normal')">
                  <xsl:attribute name="mathvariant" select="(@mathvariant, 'italic')[1]"/>
                </xsl:if>
                <xsl:apply-templates select="current-group()/@*, current-group()/node()" mode="#current"/>
              </xsl:element>
            </xsl:when>
            <xsl:when test="(current-group()/self::mtext 
                          or current-group()/self::mi[@mathvariant]
                          or current-group()/self::mspace)">
              <xsl:element name="{name()}">
                <xsl:apply-templates select="current-group()/@*[not(local-name() eq 'width')]" mode="#current"/>
                <xsl:if test="current-group()/@width">
                  <xsl:variable name="total-width" select="sum(for $i in current-group()/@width 
                                                               return xs:decimal(replace(mml:replace-literal-mspace($i), 'em$', '')))" as="xs:decimal"/>
                  <xsl:attribute name="width" select="concat(xs:string($total-width), 'em')"/>
                </xsl:if>
                <xsl:apply-templates select="current-group()/node()" mode="#current"/>
              </xsl:element>
            </xsl:when>
            <xsl:otherwise>
              <xsl:apply-templates select="current-group()" mode="#current"/>
            </xsl:otherwise>
          </xsl:choose>
        
      </xsl:for-each-group>
      
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="*[local-name() = ('msub', 'msup')]
                        [empty((*[1]/@*, *[1]/node()))]
                        [following-sibling::*[1]
                                             [local-name() = current()/local-name()]]"
                mode="mml2tex-grouping">
    <xsl:variable name="localname" select="local-name()"/>
    <xsl:variable name="next-non-group-el" select="following-sibling::*[not(local-name() = $localname)][1]/generate-id()"/>
    <xsl:copy>
      <xsl:apply-templates select="*[1]" mode="#current"/>
      <xsl:variable name="mrow">
        <mrow>
          <xsl:apply-templates
            select="*[2], following-sibling::*[following-sibling::*/generate-id() = $next-non-group-el]/*[2]"
            mode="#current">
            <xsl:with-param name="dissolve-mrow" select="true()"/>
          </xsl:apply-templates>
        </mrow>
      </xsl:variable>
      <xsl:apply-templates select="$mrow" mode="#current"/>
    </xsl:copy>
  </xsl:template>
    
  <xsl:template match="mrow" mode="mml2tex-grouping">
    <xsl:param name="dissolve-mrow" select="false()"/>
    <xsl:choose>
      <xsl:when test="$dissolve-mrow">
        <xsl:apply-templates mode="#current"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:next-match/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
    
  <xsl:template match="*[local-name() = ('msub', 'msup')]
                        [empty((*[1]/@*, *[1]/node()))]
                        [preceding-sibling::*[1]
                                             [local-name() = current()/local-name()]]" 
                mode="mml2tex-grouping" priority="2"/>
  
  <!-- conclude three single mo elements with the '.' character to horizontal ellipsis -->
  <xsl:template match="mo[. = '.']
                         [preceding-sibling::*[1]/self::mo[. = '.'][not(preceding-sibling::*[1]/self::mo[. = '.'])]]
                         [following-sibling::*[1]/self::mo[. = '.'][not(following-sibling::*[1]/self::mo[. = '.'])]]" mode="mml2tex-preprocess">
    <mo>
      <xsl:value-of select="'&#x2026;'"/>
    </mo>
  </xsl:template>
  
  <!-- transform literal mspace width values to em -->
  
  <xsl:function name="mml:replace-literal-mspace" as="xs:string">
    <xsl:param name="width" as="xs:string"/>
    <xsl:variable name="em-width" as="xs:decimal?" 
      select="     if($width eq 'veryverythinmathspace')          then  0.055
              else if($width eq 'verythinmathspace')              then  0.111
              else if($width eq 'thinmathspace')                  then  0.167
              else if($width eq 'mediummathspace')                then  0.222
              else if($width eq 'thickmathspace')                 then  0.277
              else if($width eq 'verythickmathspace')             then  0.333
              else if($width eq 'veryverythickmathspace')         then  0.388
              else if($width eq 'negativeveryverythinmathspace')  then -0.055
              else if($width eq 'negativeverythinmathspace')      then -0.111
              else if($width eq 'negativethinmathspace')          then -0.167
              else if($width eq 'negativemediummathspace')        then -0.222
              else if($width eq 'negativethickmathspace')         then -0.277
              else if($width eq 'negativeverythickmathspace')     then -0.333
              else if($width eq 'negativeveryverythickmathspace') then -0.388
              else                                                     ()"/>
    <xsl:sequence select="if(exists($em-width)) then concat($em-width, 'em') else $width"/>
  </xsl:function>
  
  <xsl:template match="mspace[matches(@width, '^[a-z]+$')]/@width" mode="mml2tex-grouping">
      <xsl:attribute name="width" select="mml:replace-literal-mspace(.)"/>
  </xsl:template>
  
  <xsl:template match="  mo[. = '.']
                           [not(following-sibling::*[1]/self::mo[. = '.'])]
                           [preceding-sibling::*[1]/self::mo[. = '.']]
                           [preceding-sibling::*[2]/self::mo[. = '.']]
                           [not(preceding-sibling::*[3]/self::mo[. = '.'])]
                       | mo[. = '.']
                           [not(preceding-sibling::*[1]/self::mo[. = '.'])]
                           [following-sibling::*[1]/self::mo[. = '.']]
                           [following-sibling::*[2]/self::mo[. = '.']]
                           [not(following-sibling::*[3]/self::mo[. = '.'])]" mode="mml2tex-preprocess"/>
  
  <!-- resolve empty mi, mn, mo -->
  
  <xsl:template match="mi[not(normalize-space(.)) and not(processing-instruction())]
                      |mo[not(normalize-space(.)) and not(processing-instruction())]
                      |mn[not(normalize-space(.)) and not(processing-instruction())]" mode="mml2tex-preprocess"/>
  
  <!-- resolve msubsup if superscript and subscript is empty -->
  
  <xsl:template match="msubsup[every $i in (*[2], *[3]) satisfies matches($i, concat('^[', $whitespace-regex, ']+$')) or not(exists($i/node()))]" priority="10" mode="mml2tex-preprocess">
    <xsl:apply-templates select="*[1]" mode="#current"/>
  </xsl:template>
  
  <!-- convert msubsup to msub if superscript is empty -->
  
  <xsl:template match="msubsup[exists(*[2]/node()) 
                               and (*[3]/self::mspace
                                    or matches(*[3], concat('^[', $whitespace-regex, ']+$')) 
                                    or not(exists(*[3]/node())))]" mode="mml2tex-preprocess">
    <msub xmlns="http://www.w3.org/1998/Math/MathML">
      <xsl:apply-templates select="@*, node() except *[3]" mode="#current"/>
    </msub>
  </xsl:template>
  
  <!-- resolve munder if underscript is empty -->
  
  <xsl:template match="*[local-name() = ('mover', 'munder')]
                        [*[2]/self::mspace 
                        or matches(*[2], concat('^[', $whitespace-regex, ']+$'))]" mode="mml2tex-preprocess">
    <xsl:apply-templates select="*[1]" mode="#current"/>
  </xsl:template>

  <!-- map combining dot above (i.e. <mml:mtext>V̇O</mml:mtext>) to mml:mover -->
  <xsl:template match="mtext[matches(., '.[&#x300;-&#x36f;&#x2d9;]')]" mode="mml2tex-grouping"
     xmlns="http://www.w3.org/1998/Math/MathML">
    <xsl:variable name="context" select="."/>
    <xsl:analyze-string select="." regex="(.)([&#x300;-&#x36f;&#x2d9;])">
      <xsl:matching-substring>
        <mover>
          <mi>
            <xsl:attribute name="mathvariant" select="'normal'"/>
            <xsl:apply-templates select="$context/@*"/>
            <xsl:value-of select="regex-group(1)"/>
          </mi>
          <mo>
            <xsl:value-of select="regex-group(2)"/>
          </mo>
        </mover>
      </xsl:matching-substring>
      <xsl:non-matching-substring>
        <xsl:element name="{if(string-length(.) = 1) then 'mi' else 'mtext'}">
          <xsl:attribute name="mathvariant" select="'normal'"/>
          <xsl:apply-templates select="$context/@*"/>
          <xsl:value-of select="."/>
        </xsl:element>
      </xsl:non-matching-substring>
    </xsl:analyze-string>
  </xsl:template>

  <xsl:template mode="mml2tex-grouping" xmlns="http://www.w3.org/1998/Math/MathML"
    match="*[local-name() = ('math', 'mrow')]/mi[following-sibling::node()[1]/self::mo[matches(., '^[&#x300;-&#x36f;&#x2d9;]$')]]">
    <mover>
      <mi>
        <xsl:apply-templates select="@*, node()"/>
      </mi>
      <mo>
        <xsl:text>&#x2d9;</xsl:text>
      </mo>
    </mover>
  </xsl:template>
  <xsl:template mode="mml2tex-grouping"
    match="*[local-name() = ('math', 'mrow')]/mo[matches(., '^[&#x300;-&#x36f;&#x2d9;]$')][preceding-sibling::node()[1]/self::mi]"/>

  <!-- regroup msubsups with empty argument -->
  
  <xsl:template match="*[local-name() = ('mi', 'mn', 'mtext')]
                        [following-sibling::*[1][self::msubsup 
                                                 and *[1][matches(., concat('^[', $whitespace-regex, ']$'))]
                                                 and not(*[2][matches(., concat('^[', $whitespace-regex, ']$'))])
                                                 and not(*[3][matches(., concat('^[', $whitespace-regex, ']$'))])
                                                 ]]" mode="mml2tex-preprocess" priority="+10.1"/>
  
  <xsl:template match="msubsup[*[1][matches(., concat('^[', $whitespace-regex, ']$'))]
                               and not(*[2][matches(., concat('^[', $whitespace-regex, ']$'))])
                               and not(*[3][matches(., concat('^[', $whitespace-regex, ']$'))])]
                               [preceding-sibling::*[1][local-name() = ('mi', 'mn', 'mtext')]]/*[1][matches(., concat('^[', 
                                                                                                                     $whitespace-regex, 
                                                                                                                     ']$'))]" mode="mml2tex-preprocess">
    <xsl:copy-of select="parent::*/preceding-sibling::*[1]"/>
  </xsl:template>

  <!-- convert msubsup to msup if subscript is empty -->
  
  <xsl:template match="msubsup[exists(*[3]/node()) 
                               and (*[2]/self::mspace
                                    or matches(*[2], concat('^[', $whitespace-regex, ']+$')) 
                                    or not(exists(*[2]/node())))]" mode="mml2tex-preprocess">
    <msup xmlns="http://www.w3.org/1998/Math/MathML">
      <xsl:apply-templates select="@*, node() except *[2]" mode="#current"/>
    </msup>
  </xsl:template>
  
  <!-- resolve msub/msup with empty exponent -->
  
  <xsl:template match="*[local-name() = ('msub', 'msup')]
                        [*[2]/self::mspace 
                         or matches(*[2], concat('^[', $whitespace-regex, ']+$')) 
                         or not(exists(*[2]/node()))]" mode="mml2tex-preprocess">
    <xsl:apply-templates select="*[1]" mode="#current"/>
  </xsl:template>
  
  <!-- dissolve mspace less equal than mspace treshold -->
  
  <xsl:template match="mspace[not(@linebreak)]
                             [xs:decimal(replace(@width, 'em$', '')) le $remove-mspace-treshold-em]
                             [not(preceding-sibling::*[1]/self::mtext or following-sibling::*[1]/self::mtext)]"
                mode="mml2tex-preprocess">
    <xsl:text>&#x20;</xsl:text>
  </xsl:template>
  
  <!-- remove space preceded or followed by operators-->
  
  <xsl:template match="mspace[not(@linebreak)]
                             [xs:decimal(replace(@width, 'em$', '')) le 0.25]
                             [preceding-sibling::*[1]/self::mo or following-sibling::*[1]/self::mo]"
                priority="5" mode="mml2tex-preprocess">
  </xsl:template>
  
  <!-- render thinspace between numbers and units -->
  
  <xsl:template mode="mml2tex-preprocess" priority="2"
                match="mspace[xs:decimal(replace(@width, 'em$', '')) le 0.25]
                             [matches(normalize-space(string-join(preceding-sibling::*[1]//text(), '')), '\d$')
                              and matches(normalize-space(string-join(following-sibling::*[1], '')), 
                                          concat('^', $sil-unit-prefixes-regex, '?', $sil-units-regex))]">
    <mspace width="0.16em">
      <xsl:apply-templates select="@* except @linebreak" mode="#current"/>
    </mspace>
  </xsl:template>
  
  <xsl:template match="*[local-name() = ('mi', 'mtext')][. eq ' ']
                        [matches(normalize-space(string-join(preceding-sibling::*[1]//text(), '')), '\d$')
                         and matches(normalize-space(string-join(following-sibling::*[1], '')), concat('^', $sil-unit-prefixes-regex, '?', $sil-units-regex))]" mode="mml2tex-preprocess" priority="2">
    <mspace width="0.16em"/>
  </xsl:template>

  <!-- repair msup/msub with more than two child elements. We assume the last node was superscripted/subscripted -->

  <xsl:template match="msup[count(*) gt 2]
		                  |msub[count(*) gt 2]" mode="mml2tex-preprocess">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <mrow xmlns="http://www.w3.org/1998/Math/MathML">
        <xsl:apply-templates select="*[not(position() eq last())]" mode="#current"/>
      </mrow>
      <xsl:apply-templates select="*[position() eq last()]" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <!-- use no msup for primes to prevent bad scaling -->
  
  <xsl:template match="msup[count(*) eq 2][matches(*[2], '^''+$')]" mode="mml2tex-preprocess">
    <xsl:apply-templates select="*" mode="#current"/>
  </xsl:template>
  
  <!-- resolve nested mmultiscripts when authors put tensors in the base of tensors by accident (MS Word equation editor) -->
  
  <xsl:template match="mmultiscripts/mrow[mmultiscripts]" mode="mml2tex-preprocess">
    <xsl:copy>
      <xsl:apply-templates select="@*, *[1]" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="mmultiscripts[mrow/mmultiscripts]" mode="mml2tex-preprocess">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
    <xsl:apply-templates select="mrow/*[position() gt 1]" mode="#current"/>
  </xsl:template>
  
  <xsl:template match="mtd[maligngroup]" mode="mml2tex-preprocess">
    <xsl:variable name="cur" select="." as="element()"/>
    <xsl:if test="$cur/*[1]/self::maligngroup and ../../mtr/mtd[not(*[1]/self::maligngroup)]">
      <mtd/>
    </xsl:if>
    <xsl:for-each-group select="node()" group-starting-with="maligngroup">
      <xsl:element name="mtd" namespace="http://www.w3.org/1998/Math/MathML">
        <xsl:attribute name="columnalign">
          <xsl:choose>
            <xsl:when test="$cur/@columnalign">
              <xsl:sequence select="$cur/@columnalign"/>
            </xsl:when>
            <xsl:when test="$cur/@groupalign">
              <xsl:sequence select="$cur/@groupalign"/>
            </xsl:when>
            <xsl:when test="current-group()[1]/self::maligngroup">left</xsl:when>
            <xsl:otherwise>right</xsl:otherwise>
          </xsl:choose>
        </xsl:attribute>
        <xsl:apply-templates select="$cur/@*, current-group()" mode="#current"/>
      </xsl:element>
    </xsl:for-each-group>
  </xsl:template>
  
  <xsl:template match="mtd/maligngroup | mtd/*[last()][self::mspace][@linebreak= 'newline']" mode="mml2tex-preprocess"/>

  <xsl:template match="*[local-name() = ('mo', 'mi', 'mtext', 'mn')]
                        [matches(., concat('^', $mml2tex:functions-names-regex, '\d+([,\.]\d+)*$'))]" mode="mml2tex-preprocess">
    <xsl:choose>
      <xsl:when test="parent::*/local-name() = $wrapper-element-names">
        <mrow>
          <xsl:apply-templates select="mml:separate-function-names(.)" mode="#current"/>
        </mrow>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="mml:separate-function-names(.)" mode="#current"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:function name="mml:separate-function-names" as="element()+">
    <xsl:param name="mml-element" as="element()"/>
    <xsl:variable name="attributes" select="$mml-element/@*" as="attribute()*"/>
    <xsl:analyze-string select="$mml-element" regex="{$mml2tex:functions-names-regex}">
      <xsl:matching-substring>
        <mi>
          <xsl:apply-templates select="$attributes"/>
          <xsl:value-of select="."/>
        </mi>
      </xsl:matching-substring>
      <xsl:non-matching-substring>
        <mn>
          <xsl:value-of select="."/>
        </mn>
      </xsl:non-matching-substring>
    </xsl:analyze-string>
  </xsl:function>
  
  <xsl:variable name="non-text-element-names" select="('mfrac', 'mn', 'mo')" as="xs:string*"/>
  
  <xsl:template match="mtext[matches(., '^[\p{Zs}&#x200b;]+$')]
                            [
                              preceding-sibling::*[1][local-name() = $non-text-element-names]
                              and
                              following-sibling::*[1][local-name() = $non-text-element-names]
                            ]" mode="mml2tex-preprocess"/>
  
  <!-- wrap private use and non-unicode-characters in mglyph -->
  
  <xsl:template match="text()[matches(., '[&#xE000;-&#xF8FF;&#xF0000;-&#xFFFFF;&#x100000;-&#x10FFFF;]')]" mode="mml2tex-preprocess">
    <xsl:analyze-string select="." regex="[&#xE000;-&#xF8FF;&#xF0000;-&#xFFFFF;&#x100000;-&#x10FFFF;]">
      <xsl:matching-substring>
        <mglyph alt="{.}"/>
      </xsl:matching-substring>
      <xsl:non-matching-substring>
        <xsl:value-of select="."/>
      </xsl:non-matching-substring>
    </xsl:analyze-string>
  </xsl:template>
  
  <!-- parse mtext and map to proper mathml elements -->
  
  <xsl:variable name="mi-regex" as="xs:string" 
                select="concat('((', 
                               $mml2tex:functions-names-regex, 
                               ')|([a-zA-Z&#x391;-&#x3f6;])'
                               ,')')"/>
  
  <xsl:template match="mtext[matches(., concat('^\s*', $mi-regex, '\s*$'))]" mode="mml2tex-preprocess">
    <xsl:element name="{mml:gen-name(parent::*, 'mi')}">
      <xsl:attribute name="mathvariant" select="'normal'"/>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:value-of select="normalize-space(.)"/>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="mtext[matches(., '^\s*[0-9]+\s*$')]" mode="mml2tex-preprocess">
    <xsl:element name="{mml:gen-name(parent::*, 'mn')}">
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:value-of select="normalize-space(.)"/>
    </xsl:element>
  </xsl:template>
  
  <xsl:variable name="non-whitespace-element-names" select="('mn', 'mo')" as="xs:string+"/>
  
  <xsl:variable name="punctuation-marks" select="('.', ',', ';', '․', '‥', '…')" as="xs:string+"/>
  
  <xsl:template match="mtext[matches(., concat('^[', $whitespace-regex, ']+$'))]
                            [not(parent::*/local-name() = $wrapper-element-names)]
                            [preceding::*[1]/ancestor-or-self::*[local-name() = ($non-whitespace-element-names, $non-text-element-names)][not(. = $punctuation-marks)] or
                             following::*[1]/self::*[local-name() = ($non-whitespace-element-names, $non-text-element-names)][not(. = $punctuation-marks)]]" 
                mode="mml2tex-preprocess" priority="1">
    <!-- Assigned priority to this template because it conflicted with the template in line 248 (as at this commit).
      It shouldn’t matter because they have the same effect. Only to avoid the warning. -->
  </xsl:template>
  
  <xsl:template match="mtext[matches(., concat('^\s*', $mml2tex:operators-regex, '\s*$'))]
                            [not(matches(., concat('^[', $whitespace-regex, ']+$')))]" mode="mml2tex-preprocess">
    <xsl:element name="{mml:gen-name(parent::*, 'mo')}">
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:value-of select="normalize-space(.)"/>
    </xsl:element>
  </xsl:template>
  
  <!-- to-do group mtext in 1st mode and text heurstics in another mode or try matching to mtext/text() -->
  
  <xsl:template match="mtext[not(   matches(., 
                                         concat('^[', $whitespace-regex, ']+$')) 
                                 or processing-instruction())]" 
                mode="mml2tex-preprocess" priority="10">
    <xsl:param name="regular-words-regex" select="'(\p{L}\p{L}+)([-\s]\p{L}\p{L}+)+\s*'" as="xs:string" tunnel="yes"/>
    <!-- prevent some characters from faulty rendering
      e.g. a legitimate en-dash = - - = would become visible double-minus 
    => keep it as mtext, hopefully becomes \text environment -->
    <xsl:variable name="context" as="element(mtext)" select="."/>
    <xsl:variable name="text-char-regex" as="xs:string" 
                  select="concat('[',
                                 '&#x2013;-&#x2014;',
                                 '&#x201c;-&#x201f;',
                                 '&#xc0;-&#xd6;', 
                                 '&#xd9;-&#xf6;',
                                 '&#xf9;-&#x1fd;',
                                 ']')"/>
    <xsl:variable name="current" select="." as="element(mtext)"/>
    <xsl:variable name="parent" select="parent::*" as="element()"/>
    <xsl:variable name="attributes" select="@*" as="attribute()*"/>
    <xsl:variable name="mathvariant" 
                  select="(@mathvariant, 
                           'bold-italic'[current()/@fontweight='bold']
                                        [current()/@fontstyle='italic'], 
                           @fontweight, 
                           @fontstyle, 
                           'normal')[1]" as="xs:string"/>
    <xsl:variable name="new-mathml" as="element()*">

      <xsl:analyze-string select="." regex="{$regular-words-regex}">
  
        <!-- preserve hyphenated words -->
        <xsl:matching-substring>
          <xsl:element name="{mml:gen-name($parent, 'mtext')}">
            <xsl:apply-templates select="$attributes" mode="#current"/>
            <xsl:value-of select="."/>
          </xsl:element>
        </xsl:matching-substring>
        <xsl:non-matching-substring>
          <!-- tag operators -->
          <xsl:analyze-string select="." regex="{$mml2tex:operators-regex}">
            
            <xsl:matching-substring>
              <xsl:element name="{mml:gen-name($parent, 'mo')}">
                <xsl:apply-templates select="$attributes" mode="#current"/>
                <xsl:value-of select="normalize-space(.)"/>
              </xsl:element>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
              
              <xsl:analyze-string select="." regex="{concat('(\s', $mi-regex, '\s)|(^\s?', $mi-regex, '\s?$)|(\s', $mi-regex, '$)|(^', $mi-regex, '\s)')}">
                
                <!-- tag identifiers -->
                <xsl:matching-substring>
                  <xsl:element name="{mml:gen-name($parent, 'mi')}">
                    <xsl:attribute name="mathvariant" select="$mathvariant"/>
                    <xsl:apply-templates select="$attributes[not(local-name() eq 'mathvariant')]" mode="#current"/>
                    <xsl:value-of select="normalize-space(.)"/>
                  </xsl:element>
                </xsl:matching-substring>
                <xsl:non-matching-substring>
                  
                  <!-- tag numerical values -->
                  <xsl:analyze-string select="." regex="[0-9]+">
                    
                    <xsl:matching-substring>
                      <xsl:element name="{mml:gen-name($parent, 'mn')}">
                        <xsl:apply-templates select="$attributes" mode="#current"/>
                        <xsl:value-of select="normalize-space(.)"/>
                      </xsl:element>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                      
                      <!-- tag derivates -->
                      <xsl:analyze-string select="." regex="([a-zA-Z]+)('+)+">
                        
                        <xsl:matching-substring>
                          <xsl:element name="{mml:gen-name($parent, 'mi')}">
                            <xsl:attribute name="mathvariant" select="$mathvariant"/>
                            <xsl:apply-templates select="$attributes[not(local-name() eq 'mathvariant')]" mode="#current"/>
                            <xsl:value-of select="regex-group(1)"/>
                          </xsl:element>
                          <xsl:element name="{mml:gen-name($parent, 'mo')}">
                            <xsl:apply-templates select="$attributes" mode="#current"/>
                            <xsl:value-of select="regex-group(2)"/>
                          </xsl:element>
                        </xsl:matching-substring>
                        
                        <xsl:non-matching-substring>
                          
                          <!-- tag greeks  -->
                          <xsl:analyze-string select="." regex="[&#xf0;&#x131;&#x391;-&#x3c9;&#x3d0;-&#x3d2;&#x3d5;]">
                            
                            <xsl:matching-substring>
                              <xsl:element name="{mml:gen-name($parent, 'mi')}">
                                <xsl:attribute name="mathvariant" select="$mathvariant"/>
                                <xsl:apply-templates select="$attributes[not(local-name() eq 'mathvariant')]" mode="#current"/>
                                <xsl:value-of select="normalize-space(.)"/>
                              </xsl:element>
                            </xsl:matching-substring>
                            <xsl:non-matching-substring>
                              <!-- map characters to mi -->
                              <xsl:choose>
                                <xsl:when test="string-length(normalize-space(.)) lt 4
                                                and not($current/@xml:space eq 'preserve')
                                                and not(matches(., $text-char-regex))
                                                ">
                                  <xsl:element name="{mml:gen-name($parent, 'mi')}">
                                    <xsl:attribute name="mathvariant" select="$mathvariant"/>
                                    <xsl:apply-templates select="$attributes[not(local-name() eq 'mathvariant')]" mode="#current"/>
                                    <xsl:value-of select="normalize-space(.)"/>
                                  </xsl:element>
                                </xsl:when>
                                <xsl:when test="normalize-space(.)">
                                  <xsl:element name="{mml:gen-name($parent, 'mtext')}">
                                    <xsl:apply-templates select="$attributes" mode="#current"/>
                                    <xsl:value-of select="."/>
                                  </xsl:element>
                                </xsl:when>
                              </xsl:choose>
                            </xsl:non-matching-substring>
                            
                          </xsl:analyze-string>
                        </xsl:non-matching-substring>
                      </xsl:analyze-string>
                    </xsl:non-matching-substring>
                  </xsl:analyze-string>     
                </xsl:non-matching-substring>
              </xsl:analyze-string>
            </xsl:non-matching-substring>
          </xsl:analyze-string>
        </xsl:non-matching-substring>
      </xsl:analyze-string>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="count($new-mathml) = 0">
        <xsl:message terminate="yes" select="'Unexpected empty result from ', $context, ' (not totally unexpected: it can happen for empty mtext elements)'"/>
      </xsl:when>
      <xsl:when test="count($new-mathml) gt 1">
        <mrow>
          <xsl:sequence select="$new-mathml"/>
        </mrow>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="$new-mathml"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:function name="mml:gen-name" as="xs:string">
    <xsl:param name="parent" as="element()"/>
    <xsl:param name="name" as="xs:string"/>
    <xsl:value-of select="if(matches($parent/name(), ':')) 
                          then concat(substring-before($parent/name(), ':'), ':', $name) 
                          else $name"/>
  </xsl:function>
  
  <!-- identity template -->
  
  <xsl:template match="*|@*|processing-instruction()" mode="mml2tex-grouping mml2tex-preprocess">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()|processing-instruction()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
</xsl:stylesheet>
