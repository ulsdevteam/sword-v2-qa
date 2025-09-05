<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="embargo_relesae_date|visibility_during_embargo|visibility_after_embargo|lease_expiration_date|visiblity_during_lease|visibility_after_lease" />

  <xsl:template match="visibility">
    <xsl:copy>
      <xsl:text>embargo</xsl:text>
    </xsl:copy>
    <embargo_release_date>2036-01-01</embargo_release_date>
    <visiblity_during_embargo>authenticated</visiblity_during_embargo>
    <visiblity_after_embargo>open</visiblity_after_embargo>
  </xsl:template>

</xsl:stylesheet>
