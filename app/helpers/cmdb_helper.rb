# frozen_string_literal: true

# Helpers for rendering overridable CMDB data
module CmdbHelper
  def disabled_text_f(f, attr, **options)
    options.merge! disabled: true
    field f, attr, options do
      addClass options, "form-control"

      input_group(
        f.text_field(attr, options),
        content_tag(:a,
                    href: "#",
                    class: "input-group-addon btn btn-default",
                    title: "Edit",
                    onclick: "toggle_input_group(this); return false;") do
          content_tag(:span, "", class: "pficon pficon-edit")
        end
      )
    end
  end

  def disabled_textarea_f(f, attr, **options)
    options.merge! disabled: true
    field f, attr, options do
      addClass options, "form-control"

      input_group(
        f.text_area(attr, options),
        content_tag(:a,
                    href: "#",
                    class: "input-group-addon btn btn-default",
                    title: "Edit",
                    onclick: "toggle_input_group(this); return false;") do
          content_tag(:span, "", class: "pficon pficon-edit")
        end
      )
    end
  end
end
