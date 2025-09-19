<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:h4cmeta="https://hykucommons.org/schema/metadata" xmlns:atom="http://www.w3.org/2005/Atom" exclude-result-prefixes="h4cmeta atom">
<xsl:output method="xml" omit-xml-declaration="yes" indent="no"/>

  <xsl:template match="/atom:entry">
   <resultroot>
    <xsl:for-each select="atom:link[@rel='edit-media']">
      <result>
      <xsl:value-of select="@href" />
      </result>
    </xsl:for-each>
    </resultroot>
  </xsl:template>

</xsl:stylesheet>
