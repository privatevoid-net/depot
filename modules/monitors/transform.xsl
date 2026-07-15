<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" indent="no" encoding="UTF-8"/>
  <xsl:strip-space elements="*"/>

  <xsl:template match="/expr/list/attrs">
    <monitors version="2">
      <configuration>
        <layoutmode>
          <xsl:value-of select="attr[@name='layoutMode']/string/@value"/>
        </layoutmode>

        <xsl:apply-templates select="attr[@name='monitors']/list/attrs"/>
      </configuration>
    </monitors>
  </xsl:template>

  <xsl:template match="attrs">
    <logicalmonitor>
      <x><xsl:value-of select="attr[@name='position']/attrs/attr[@name='x']/int/@value"/></x>
      <y><xsl:value-of select="attr[@name='position']/attrs/attr[@name='y']/int/@value"/></y>
      <scale><xsl:value-of select="attr[@name='position']/attrs/attr[@name='scale']/string/@value"/></scale>

      <primary>
        <xsl:choose>
          <xsl:when test="attr[@name='primary']/bool/@value = 'true'">yes</xsl:when>
          <xsl:otherwise>no</xsl:otherwise>
        </xsl:choose>
      </primary>

      <monitor>
        <monitorspec>
          <connector><xsl:value-of select="attr[@name='spec']/attrs/attr[@name='connector']/string/@value"/></connector>
          <vendor><xsl:value-of select="attr[@name='spec']/attrs/attr[@name='vendor']/string/@value"/></vendor>
          <product><xsl:value-of select="attr[@name='spec']/attrs/attr[@name='product']/string/@value"/></product>
          <serial><xsl:value-of select="attr[@name='spec']/attrs/attr[@name='serial']/string/@value"/></serial>
        </monitorspec>

        <mode>
          <width><xsl:value-of select="attr[@name='mode']/attrs/attr[@name='width']/int/@value"/></width>
          <height><xsl:value-of select="attr[@name='mode']/attrs/attr[@name='height']/int/@value"/></height>
          <rate><xsl:value-of select="attr[@name='mode']/attrs/attr[@name='refreshRate']/string/@value"/></rate>
        </mode>

        <xsl:if test="not(attr[@name='colorMode']/null)">
          <colormode><xsl:value-of select="attr[@name='mode']/attrs/attr[@name='colorMode']/string/@value"/></colormode>
        </xsl:if>
      </monitor>
    </logicalmonitor>
  </xsl:template>
</xsl:stylesheet>
