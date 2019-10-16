<?php

require_once DOKU_INC.'lib/plugins/odt/ODT/styles/ODTStyle.php';

/**
 * Tests to ensure functionality of the ODTTableRowStyle class.
 *
 * @group plugin_odt
 * @group plugins
 */
class plugin_odt_tablerowstyle_test extends DokuWikiTest {
    public function setUp() {
        $this->pluginsEnabled[] = 'odt';
        parent::setUp();
    }

    /**
     * Test ODT XML style definition import.
     */
    public function test_simple_odt_import() {
        $xml_code = '<style:style style:name="Table1.2" style:family="table-row">
                         <style:table-row-properties style:min-row-height="2.228cm"/>
                     </style:style>';

        $style = ODTStyle::importODTStyle($xml_code);
        $this->assertNotNull($style);

        $this->assertEquals($style->getFamily(), 'table-row');
        $this->assertEquals($style->getProperty('style-name'), 'Table1.2');
        $this->assertEquals($style->getPropertySection('style-name'), 'style');
        $this->assertEquals($style->getProperty('style-family'), 'table-row');
        $this->assertEquals($style->getPropertySection('style-family'), 'style');
        $this->assertEquals($style->getProperty('min-row-height'), '2.228cm');
        $this->assertEquals($style->getPropertySection('min-row-height'), 'table-row');
    }

    /**
     * Test ODT XML style definition import and conversion to string.
     */
    public function test_import_and_to_string() {
        $xml_code = '<style:style style:name="Table1.2" style:family="table-row">
                         <style:table-row-properties style:min-row-height="2.228cm"/>
                     </style:style>';
        $expected  = '<style:style style:name="Table1.2" style:family="table-row" >'."\n";
        $expected .= '    <style:table-row-properties style:min-row-height="2.228cm" />'."\n";
        $expected .= '</style:style>'."\n";

        $style = ODTStyle::importODTStyle($xml_code);
        $this->assertNotNull($style);

        $style_string = $style->toString();

        $this->assertEquals($expected, $style_string);
    }

    /**
     * Test set and get of a property.
     */
    public function test_set_and_get() {
        $xml_code = '<style:style style:name="Table1.2" style:family="table-row">
                         <style:table-row-properties style:min-row-height="2.228cm"/>
                     </style:style>';

        $style = ODTStyle::importODTStyle($xml_code);
        $this->assertNotNull($style);

        $style->setProperty('min-row-height', '2.228cm');

        $this->assertEquals($style->getProperty('min-row-height'), '2.228cm');
    }

    /**
     * Test properties import and conversion to string.
     */
    public function test_import_properties_and_to_string() {
        $properties = array();
        $properties ['style-name']     = 'Table1.2';
        $properties ['min-row-height'] = '2.228cm';

        $expected  = '<style:style style:name="Table1.2" style:family="table-row" >'."\n";
        $expected .= '    <style:table-row-properties style:min-row-height="2.228cm" />'."\n";
        $expected .= '</style:style>'."\n";

        $style = new ODTTableRowStyle();
        $this->assertNotNull($style);

        $style->importProperties($properties, NULL);
        $style_string = $style->toString();

        $this->assertEquals($expected, $style_string);
    }
}
