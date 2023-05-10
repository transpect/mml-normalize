<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:mml="http://www.w3.org/1998/Math/MathML"
  xmlns:mml2tex="http://transpect.io/mml2tex"
  xmlns="http://www.w3.org/1998/Math/MathML"
  version="2.0"
  exclude-result-prefixes="#all" 
  xpath-default-namespace="http://www.w3.org/1998/Math/MathML">
  
  <!-- Simple markup cleanup templates. Used by mml-normalize.xsl and mml2mathmlcore.xsl -->
  
  <xsl:template match="mrow[count(*) = 1][not(@*)]" mode="mml2tex-preprocess mml-to-core">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  
</xsl:stylesheet>
