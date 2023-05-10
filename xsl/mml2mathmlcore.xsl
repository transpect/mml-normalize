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
  
  <!-- dissolve mfenced to mrow --> 
  <xsl:template match="mfenced" mode="mml-to-core">
    <xsl:variable name="context" select="." as="element(mfenced)"/>
    <mrow>
      <mo>
        <xsl:choose>
          <xsl:when test="exists(@open)">
            <xsl:apply-templates select="@open" mode="#current"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="'('"/>
          </xsl:otherwise>
        </xsl:choose>
      </mo>
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
              <xsl:if test="position() != last()">
                <mo>
                  <xsl:value-of select="($separators[$pos], $separators[last()], ',')[1]"/>
                </mo>
              </xsl:if>
            </xsl:for-each>
          </mrow>
        </xsl:otherwise>
      </xsl:choose>
      <mo>
        <xsl:choose>
          <xsl:when test="exists(@close)">
            <xsl:apply-templates select="@close" mode="#current"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="')'"/>
          </xsl:otherwise>
        </xsl:choose>
      </mo>
    </mrow>
  </xsl:template>
  
  <xsl:template match="mfenced/@open | mfenced/@close" mode="mml-to-core">
    <mo>
      <xsl:value-of select="."/>
    </mo>
  </xsl:template>
  
  <!-- identity template -->
  <xsl:template match="node() | @*" mode="mml-to-core" priority="-1">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:apply-templates select="node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
</xsl:stylesheet>
