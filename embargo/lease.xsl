<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="embargo_relesae_date|visibility_during_embargo|visibility_after_embargo|lease_expiration_date|visibility_during_lease|visibility_after_lease" />

  <xsl:template match="visibility">
    <xsl:copy>
      <xsl:text>lease</xsl:text>
    </xsl:copy>
    <lease_expiration_date>2036-01-01</lease_expiration_date>
    <visibility_during_lease>authenticated</visibility_during_lease>
    <visibility_after_lease>restrictd</visibility_after_lease>
  </xsl:template>

</xsl:stylesheet>
