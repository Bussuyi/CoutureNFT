;; CoutureNFT - Digital Fashion NFTs with Physical Redemption
;; A platform for fashion designers to create limited edition digital fashion NFTs 
;; that can be redeemed for physical items

;; Error codes
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-not-authorized (err u103))
(define-constant err-already-redeemed (err u104))
(define-constant err-sold-out (err u105))
(define-constant err-invalid-price (err u106))
(define-constant err-transfer-failed (err u107))

;; Data variables
(define-data-var contract-owner principal tx-sender)

;; Data maps
(define-map designers principal 
  {
    name: (string-ascii 50),
    verified: bool
  }
)

(define-map collections uint 
  {
    designer: principal,
    name: (string-ascii 50),
    description: (string-utf8 500),
    total-supply: uint,
    items-minted: uint,
    base-uri: (string-utf8 256),
    active: bool
  }
)

(define-map nfts (tuple (collection-id uint) (token-id uint)) 
  {
    owner: principal,
    metadata-uri: (string-utf8 256),
    redeemed: bool,
    redemption-code: (optional (buff 32))
  }
)

(define-map collection-prices uint uint) ;; collection-id -> price in uSTX

;; Read-only functions
(define-read-only (get-contract-owner)
  (var-get contract-owner)
)

(define-read-only (get-designer (designer-address principal))
  (map-get? designers designer-address)
)

(define-read-only (get-collection (collection-id uint))
  (map-get? collections collection-id)
)

(define-read-only (get-collection-price (collection-id uint))
  (default-to u0 (map-get? collection-prices collection-id))
)

(define-read-only (get-nft (collection-id uint) (token-id uint))
  (map-get? nfts {collection-id: collection-id, token-id: token-id})
)

(define-read-only (get-owner (collection-id uint) (token-id uint))
  (match (map-get? nfts {collection-id: collection-id, token-id: token-id})
    nft-data (ok (get owner nft-data))
    (err err-not-found)
  )
)

(define-read-only (is-redeemed (collection-id uint) (token-id uint))
  (match (map-get? nfts {collection-id: collection-id, token-id: token-id})
    nft-data (ok (get redeemed nft-data))
    (err err-not-found)
  )
)

;; Public functions
(define-public (register-designer (name (string-ascii 50)))
  (let ((caller tx-sender))
    (if (map-get? designers caller)
      err-already-exists
      (begin
        (map-set designers caller {name: name, verified: false})
        (ok true)
      )
    )
  )
)

(define-public (verify-designer (designer principal))
  (let ((caller tx-sender))
    (if (is-eq caller (var-get contract-owner))
      (match (map-get? designers designer)
        designer-data (begin
          (map-set designers designer (merge designer-data {verified: true}))
          (ok true)
        )
        err-not-found
      )
      err-owner-only
    )
  )
)

(define-public (create-collection 
    (collection-id uint) 
    (name (string-ascii 50)) 
    (description (string-utf8 500)) 
    (total-supply uint) 
    (base-uri (string-utf8 256))
    (price uint)
  )
  (let ((caller tx-sender))
    (match (map-get? designers caller)
      designer-data
        (if (map-get? collections collection-id)
          err-already-exists
          (begin
            (map-set collections collection-id {
              designer: caller,
              name: name,
              description: description,
              total-supply: total-supply,
              items-minted: u0,
              base-uri: base-uri,
              active: true
            })
            (map-set collection-prices collection-id price)
            (ok true)
          )
        )
      err-not-authorized
    )
  )
)

(define-public (toggle-collection-status (collection-id uint))
  (let ((caller tx-sender))
    (match (map-get? collections collection-id)
      collection-data
        (if (is-eq caller (get designer collection-data))
          (begin
            (map-set collections collection-id 
              (merge collection-data {active: (not (get active collection-data))})
            )
            (ok true)
          )
          err-not-authorized
        )
      err-not-found
    )
  )
)

(define-public (mint-nft (collection-id uint))
  (let (
    (caller tx-sender)
    (price (default-to u0 (map-get? collection-prices collection-id)))
  )
    (match (map-get? collections collection-id)
      collection-data
        (if (get active collection-data)
          (if (< (get items-minted collection-data) (get total-supply collection-data))
            (let (
              (new-token-id (get items-minted collection-data))
              (new-items-minted (+ (get items-minted collection-data) u1))
              (metadata-uri (concat (get base-uri collection-data) (to-string new-token-id)))
            )
              (if (> price u0)
                (match (stx-transfer? price caller (get designer collection-data))
                  success
                    (begin
                      (map-set collections collection-id 
                        (merge collection-data {items-minted: new-items-minted})
                      )
                      (map-set nfts {collection-id: collection-id, token-id: new-token-id} {
                        owner: caller,
                        metadata-uri: metadata-uri,
                        redeemed: false,
                        redemption-code: none
                      })
                      (ok new-token-id)
                    )
                  error err-transfer-failed
                )
                (begin
                  (map-set collections collection-id 
                    (merge collection-data {items-minted: new-items-minted})
                  )
                  (map-set nfts {collection-id: collection-id, token-id: new-token-id} {
                    owner: caller,
                    metadata-uri: metadata-uri,
                    redeemed: false,
                    redemption-code: none
                  })
                  (ok new-token-id)
                )
              )
            )
            err-sold-out
          )
          err-not-authorized
        )
      err-not-found
    )
  )
)

(define-public (transfer-nft (collection-id uint) (token-id uint) (recipient principal))
  (let ((caller tx-sender))
    (match (map-get? nfts {collection-id: collection-id, token-id: token-id})
      nft-data
        (if (is-eq caller (get owner nft-data))
          (begin
            (map-set nfts {collection-id: collection-id, token-id: token-id} 
              (merge nft-data {owner: recipient})
            )
            (ok true)
          )
          err-not-authorized
        )
      err-not-found
    )
  )
)

(define-public (set-redemption-code (collection-id uint) (token-id uint) (redemption-code (buff 32)))
  (let ((caller tx-sender))
    (match (map-get? collections collection-id)
      collection-data
        (if (is-eq caller (get designer collection-data))
          (match (map-get? nfts {collection-id: collection-id, token-id: token-id})
            nft-data
              (begin
                (map-set nfts {collection-id: collection-id, token-id: token-id} 
                  (merge nft-data {redemption-code: (some redemption-code)})
                )
                (ok true)
              )
            err-not-found
          )
          err-not-authorized
        )
      err-not-found
    )
  )
)

(define-public (redeem-nft (collection-id uint) (token-id uint))
  (let ((caller tx-sender))
    (match (map-get? nfts {collection-id: collection-id, token-id: token-id})
      nft-data
        (if (is-eq caller (get owner nft-data))
          (if (get redeemed nft-data)
            err-already-redeemed
            (if (is-some (get redemption-code nft-data))
              (begin
                (map-set nfts {collection-id: collection-id, token-id: token-id} 
                  (merge nft-data {redeemed: true})
                )
                (ok true)
              )
              err-not-authorized
            )
          )
          err-not-authorized
        )
      err-not-found
    )
  )
)

;; Admin functions
(define-public (set-contract-owner (new-owner principal))
  (let ((caller tx-sender))
    (if (is-eq caller (var-get contract-owner))
      (begin
        (var-set contract-owner new-owner)
        (ok true)
      )
      err-owner-only
    )
  )
)