<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:mml="http://www.w3.org/1998/Math/MathML"
  xmlns="http://www.w3.org/1998/Math/MathML"
  version="2.0" 
  exclude-result-prefixes="#all" 
  xpath-default-namespace="http://www.w3.org/1998/Math/MathML">
  <!--  *
        * Mapping, tweaks and normalizations of MathML (version lower or equal 4) into MathML-Core.
        *
        * Used template modes: mml-to-core 
        *
        * Documentation of target markup: https://w3c.github.io/mathml-core/
        * -->
  
  <xsl:import href="tidy-up-simple.xsl"/>
  
  <xsl:param name="to-version" select="'4-core'"/>
  <xsl:param name="from-version" select="'any'"/>
  <xsl:param name="keep-mml-prefix" select="'any'"/>
  <!-- (all|none) keep mml prefix or dissolve all  -->
  
  <!-- dissolve mfenced to mrow --> 
  <xsl:template match="mfenced" mode="mml-to-core">
    <xsl:variable name="context" select="." as="element(mfenced)"/>
    <mrow>
      <xsl:choose>
        <xsl:when test="exists(@open)">
          <xsl:apply-templates select="@open" mode="#current"/>
        </xsl:when>
        <xsl:otherwise>
          <mo stretchy="true">
            <xsl:value-of select="'('"/>
          </mo>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:choose>
        <xsl:when test="count(*) = 1">
          <xsl:apply-templates mode="#current"/>
        </xsl:when>
        <xsl:otherwise>
          <mrow>
            <xsl:for-each select="*">
              <xsl:apply-templates select="." mode="#current"/>
              <xsl:variable name="pos" select="position()"/>
              <xsl:variable name="separators" 
                select="for $i in (1 to string-length($context/@separators/normalize-space())) 
                        return substring($context/@separators/normalize-space(), $i, 1)"/>
              <xsl:if test="position() != last() and ($context/@separators!='') ">
                <mo>
                  <xsl:value-of select="($separators[$pos], $separators[last()], ',')[1]"/>
                </mo>
              </xsl:if>
            </xsl:for-each>
          </mrow>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:choose>
        <xsl:when test="exists(@close)">
          <xsl:apply-templates select="@close" mode="#current"/>
        </xsl:when>
        <xsl:otherwise>
          <mo stretchy="true">
            <xsl:value-of select="')'"/>
          </mo>
        </xsl:otherwise>
      </xsl:choose>
    </mrow>
  </xsl:template>
  
  <xsl:template match="mfenced/@open | mfenced/@close" mode="mml-to-core">
    <mo stretchy="true">
      <xsl:value-of select="."/>
    </mo>
  </xsl:template>
  
  <!-- identity template -->
  <xsl:template match="@* | node()"  mode="mml-to-core mml-prefix">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="*[namespace-uri()='http://www.w3.org/1998/Math/MathML'][$keep-mml-prefix='all']"  mode="mml-prefix">
    <xsl:element name="mml:{local-name()}">
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="*[matches(name(.),'^mml:')][$keep-mml-prefix='none']"  mode="mml-prefix">
    <xsl:element name="{local-name()}">
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:element>
  </xsl:template>
  
</xsl:stylesheet>
