Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"

  root "pages#index"

  get "/codepoint/:codepoint",
      to: "pages#show",
      constraints: { codepoint: /[0-9A-F]{4,6}/ }

  # --- 正規化されていない /codepoint/:codepoint を正規URLに 301 リダイレクト ---
  # 例:
  #   /codepoint/a      → /codepoint/000A
  #   /codepoint/41     → /codepoint/0041
  #   /codepoint/1f600  → /codepoint/1F600
  get "/codepoint/:codepoint", to: redirect { |params, _req|
    codepoint = params[:codepoint].to_s

    # U+付きで来た場合も一応ケアしておく (U+0041 → 0041)
    codepoint = codepoint.sub(/\A[Uu]\+?/, "")

    # 余計な文字は落として大文字化
    codepoint = codepoint.gsub(/[^0-9A-Fa-f]/, "").upcase

    # 4桁未満なら左ゼロ埋め（Unicodeの基本多言語面と相性が良い）
    codepoint = codepoint.rjust(4, "0") if codepoint.length < 4

    "/codepoint/#{codepoint}"
  }, constraints: { codepoint: /.+/ }

  # --- 短縮形 /cp/:codepoint → /codepoint/:codepoint に 301 リダイレクト ---
  # 例:
  #   /cp/a      → /codepoint/000A
  #   /cp/1f600  → /codepoint/1F600
  get "/cp/:codepoint", to: redirect { |params, _req|
    codepoint = params[:codepoint].to_s
    "/codepoint/#{codepoint}"
  }, constraints: { codepoint: /.+/ }
end
