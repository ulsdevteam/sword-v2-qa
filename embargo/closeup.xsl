<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="embargo_relesae_date|visibility_during_embargo|visibility_after_embargo|lease_expiration_date|visiblity_during_lease|visibility_after_lease" />

  <xsl:template match="visibility">
    <xsl:copy>
      <xsl:text>authenticated</xsl:text>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
