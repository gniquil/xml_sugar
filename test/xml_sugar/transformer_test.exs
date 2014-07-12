defmodule XmlSugar.TransformerTest do
  use ExUnit.Case
  import XmlSugar.Transformer

  test "transform any_descendant" do
    assert transform("ul li") == "//ul//li"
    assert transform("ul li a") == "//ul//li//a"
  end

  test "transform direct_descendant" do
    assert transform("ul > li") == "//ul/li"
    assert transform("ul>li") == "//ul/li"
    assert transform("ul[class='active'] > li") == "//ul[@class=\"active\"]/li"
    assert transform("ul > li > a") == "//ul/li/a"
  end

  test "transform immediate siblings" do
    assert transform("h1 + p") == "//h1/following-sibling::*[1]/self::p"
  end

  test "transform attribute" do
    assert transform("h1[attr]") == "//h1[@attr]"
    assert transform("h1[attr='active']") == "//h1[@attr=\"active\"]"
    assert transform("h1[attr~='active']") == "//h1[contains(concat(' ', @attr, ' '), ' active ')]"
    assert transform("h1[attr*='active']") == "//h1[contains(@attr, 'active')]"
    assert transform("h1[attr^='active']") == "//h1[starts-with(@attr, 'active')]"
    assert transform("h1[attr$='active']") == "//h1[ends-with(@attr, 'active')]"
    assert transform("h1[attr='active'][attr2='inactive']") == "//h1[@attr=\"active\"][@attr2=\"inactive\"]"

    assert transform("[attr]") == "//*[@attr]"
    assert transform("[attr='active']") == "//*[@attr=\"active\"]"
    assert transform("[attr~='active']") == "//*[contains(concat(' ', @attr, ' '), ' active ')]"
    assert transform("[attr*='active']") == "//*[contains(@attr, 'active')]"
    assert transform("[attr^='active']") == "//*[starts-with(@attr, 'active')]"
    assert transform("[attr$='active']") == "//*[ends-with(@attr, 'active')]"
    assert transform("[attr='active'][attr2='inactive']") == "//*[@attr=\"active\"][@attr2=\"inactive\"]"
  end

  test "transform hash" do
    assert transform("h1#my-title") == "//h1[@id=\"my-title\"]"
    assert transform("h1#my-title[attr='active']") == "//h1[@id=\"my-title\"][@attr=\"active\"]"
    assert transform("#my-title") == "//*[@id=\"my-title\"]"
  end

  test "transform class" do
    assert transform("h1.active") == "//h1[contains(concat(' ', @class, ' '), ' active ')]"
    assert transform("h1.active.red") == "//h1[contains(concat(' ', @class, ' '), ' active ')][contains(concat(' ', @class, ' '), ' red ')]"
    assert transform(".active.red") == "//*[contains(concat(' ', @class, ' '), ' active ')][contains(concat(' ', @class, ' '), ' red ')]"
  end

  test "first and last child" do
    assert transform("header p:first-child") == "//header//p[1]"
    assert transform("header p:last-child") == "//header//p[last()]"
  end

  test "nth-child" do
    assert transform("header p:nth-child(2)") == "//header//p[2]"
    assert transform("header p:nth-child(10)") == "//header//p[10]"
    assert transform("header p:nth-child(odd)") == "//header//p[position() mod 2 = 1]"
    assert transform("header p:nth-child(even)") == "//header//p[position() mod 2 = 0]"
    assert transform("header p:nth-child(3n+2)") == "//header//p[position() mod 3 = 2 and position() > 2]" # note no space is allowed here
  end
end
