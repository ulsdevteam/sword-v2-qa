<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:h4cmeta="https://hykucommons.org/schema/metadata" xmlns:atom="http://www.w3.org/2005/Atom" exclude-result-prefixes="h4cmeta atom">

  <xsl:template match="h4cmeta:*">
    <xsl:variable name="eName">
      <xsl:value-of select="local-name()" />
    </xsl:variable>
    <xsl:element name="{$eName}">
      <xsl:value-of select="." />
    </xsl:element>
  </xsl:template>

  <xsl:template match="/atom:entry">
    <metadata>
    <xsl:apply-templates select="//h4cmeta:*" />
    </metadata>
  </xsl:template>

</xsl:stylesheet>
