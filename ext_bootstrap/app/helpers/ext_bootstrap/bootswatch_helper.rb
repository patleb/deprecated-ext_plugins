# TODO sprocket is slow --> refactor with require

module ExtBootstrap
  module BootswatchHelper
    BOOTSWATCH_FONTS = {
      cosmo:      [300, 400, 700],
      cyborg:     [400, 700],
      darkly:     [400, 'italic', 700],
      flatly:     [400, 'italic', 700],
      journal:    [400, 700],
      lumen:      [300, 400, 'italic', 700],
      paper:      [300, 400, 500, 700],
      readable:   [400, 700],
      sandstone:  [400, 500, 700],
      simplex:    [400, 700],
      spacelab:   [400, 'italic', 700, 'italic'],
      superhero:  [300, 400, 700],
      united:     [400, 700],
      yeti:       [300, 'italic', 400, 'italic', 700, 'italic'],
    }.freeze

    def bootswatch_fonts_prefetch(*sizes)
      if sizes.empty?
        sizes = BOOTSWATCH_FONTS[ExtBootstrap.config.theme.to_sym] || []
      end

      previous = nil
      html sizes.flatten.map{ |weight_or_style|
        weight, style =
          if weight_or_style.is_a? String
            [previous, weight_or_style]
          else
            [weight_or_style, 'normal']
          end
        tag = div "prefetch-font-#{weight}-#{style}", style: "opacity: 0; position: absolute; left: -999em; font-weight: #{weight}; font-style: #{style};"
        previous = weight_or_style
        tag
      }
    end
  end
end
