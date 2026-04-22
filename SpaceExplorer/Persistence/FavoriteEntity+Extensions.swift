import CoreData

extension FavoriteEntity {

    // MARK: - Convert to/from domain model

    func toAstronomyPicture() -> AstronomyPicture {
        AstronomyPicture(
            date: date ?? "",
            explanation: explanation ?? "",
            hdurl: hdurl,
            mediaType: mediaType ?? "image",
            serviceVersion: nil,
            title: title ?? "",
            url: url ?? "",
            copyright: copyright,
            thumbnailUrl: thumbnailUrl
        )
    }

    static func from(_ picture: AstronomyPicture, context: NSManagedObjectContext) -> FavoriteEntity {
        let entity = FavoriteEntity(context: context)
        entity.id = picture.id
        entity.date = picture.date
        entity.explanation = picture.explanation
        entity.hdurl = picture.hdurl
        entity.mediaType = picture.mediaType
        entity.title = picture.title
        entity.url = picture.url
        entity.copyright = picture.copyright
        entity.thumbnailUrl = picture.thumbnailUrl
        entity.savedAt = Date()
        return entity
    }

    // MARK: - Fetch requests

    static func fetchRequest(for id: String) -> NSFetchRequest<FavoriteEntity> {
        let request = NSFetchRequest<FavoriteEntity>(entityName: "FavoriteEntity")
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        return request
    }

    static func allFetchRequest() -> NSFetchRequest<FavoriteEntity> {
        let request = NSFetchRequest<FavoriteEntity>(entityName: "FavoriteEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "savedAt", ascending: false)]
        return request
    }
}
